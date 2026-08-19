#define _GNU_SOURCE

#include <dlfcn.h>
#include <pthread.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/socket.h>
#include <sys/types.h>
#include <sys/uio.h>
#include <unistd.h>

/*
 * Yandex Browser Corporate native-Wayland geometry sanitizer, final quiet version.
 *
 * Chromium bundles its own hidden libwayland-client, so patching the public
 * libwayland-client does not affect Ozone. LD_PRELOAD also propagates to
 * renderer/utility children, so the interposer must not probe arbitrary fds
 * with syscalls forbidden by Chromium's seccomp sandbox.
 *
 * This final version performs NO socket-probing syscalls and does not interpose
 * connect(). On sendmsg() it only inspects the already-present userspace
 * iovec bytes. An fd becomes a Wayland candidate only after an exact
 * wl_display.get_registry(new_id) request is observed. It becomes useful for
 * mutation only after that registry subsequently binds "xdg_wm_base" and
 * creates the corresponding xdg_surface/xdg_positioner object IDs.
 *
 * Unrelated Chromium Mojo/IPC sockets are passed to the real sendmsg()
 * unchanged. No Wayland proxy is introduced; DMA-BUF, explicit sync, input,
 * buffers, app_id, etc. still go directly to KWin.
 */

typedef ssize_t (*sendmsg_fn)(int, const struct msghdr *, int);
typedef int (*close_fn)(int);

static pthread_once_t symbols_once = PTHREAD_ONCE_INIT;
static sendmsg_fn real_sendmsg;
static close_fn real_close;

struct idset {
    uint32_t *ids;
    size_t len;
    size_t cap;
};

struct fd_state {
    int fd;
    int saw_registry_request;
    int confirmed_xdg_shell;
    struct idset registries;
    struct idset xdg_wm_bases;
    struct idset xdg_surfaces;
    struct idset xdg_positioners;
    struct fd_state *next;
};

static pthread_mutex_t states_lock = PTHREAD_MUTEX_INITIALIZER;
static struct fd_state *states;

static void resolve_symbols(void)
{
    *(void **)(&real_sendmsg) = dlsym(RTLD_NEXT, "sendmsg");
    *(void **)(&real_close) = dlsym(RTLD_NEXT, "close");

    if (!real_sendmsg || !real_close) {
        const char *e = dlerror();
        dprintf(STDERR_FILENO,
                "yandex-wayland-wire: symbol resolution failed: %s\n",
                e ? e : "unknown error");
        _exit(127);
    }
}

static int idset_contains(const struct idset *set, uint32_t id)
{
    size_t i;
    for (i = 0; i < set->len; ++i)
        if (set->ids[i] == id)
            return 1;
    return 0;
}

static void idset_add(struct idset *set, uint32_t id)
{
    uint32_t *new_ids;
    size_t new_cap;

    if (!id || idset_contains(set, id))
        return;

    if (set->len == set->cap) {
        new_cap = set->cap ? set->cap * 2 : 16;
        new_ids = realloc(set->ids, new_cap * sizeof(*new_ids));
        if (!new_ids)
            return;
        set->ids = new_ids;
        set->cap = new_cap;
    }

    set->ids[set->len++] = id;
}

static void idset_remove(struct idset *set, uint32_t id)
{
    size_t i;
    for (i = 0; i < set->len; ++i) {
        if (set->ids[i] == id) {
            set->ids[i] = set->ids[set->len - 1];
            --set->len;
            return;
        }
    }
}

static void idset_free(struct idset *set)
{
    free(set->ids);
    memset(set, 0, sizeof(*set));
}

static struct fd_state *find_state_locked(int fd)
{
    struct fd_state *s;
    for (s = states; s; s = s->next)
        if (s->fd == fd)
            return s;
    return NULL;
}

static struct fd_state *get_state_locked(int fd)
{
    struct fd_state *s = find_state_locked(fd);

    if (s)
        return s;

    s = calloc(1, sizeof(*s));
    if (!s)
        return NULL;

    s->fd = fd;
    s->next = states;
    states = s;
    return s;
}

static void remove_state_locked(int fd)
{
    struct fd_state **p = &states;

    while (*p) {
        struct fd_state *s = *p;

        if (s->fd == fd) {
            *p = s->next;
            idset_free(&s->registries);
            idset_free(&s->xdg_wm_bases);
            idset_free(&s->xdg_surfaces);
            idset_free(&s->xdg_positioners);
            free(s);
            return;
        }

        p = &s->next;
    }
}

static int iov_read(const struct msghdr *msg, size_t off, void *dst, size_t len)
{
    size_t i, n;
    unsigned char *out = dst;

    for (i = 0; i < msg->msg_iovlen && len; ++i) {
        const struct iovec *v = &msg->msg_iov[i];

        if (off >= v->iov_len) {
            off -= v->iov_len;
            continue;
        }

        n = v->iov_len - off;
        if (n > len)
            n = len;

        memcpy(out, (const unsigned char *)v->iov_base + off, n);
        out += n;
        len -= n;
        off = 0;
    }

    return len == 0;
}

static int iov_write(const struct msghdr *msg, size_t off,
                     const void *src, size_t len)
{
    size_t i, n;
    const unsigned char *in = src;

    for (i = 0; i < msg->msg_iovlen && len; ++i) {
        const struct iovec *v = &msg->msg_iov[i];

        if (off >= v->iov_len) {
            off -= v->iov_len;
            continue;
        }

        n = v->iov_len - off;
        if (n > len)
            n = len;

        memcpy((unsigned char *)v->iov_base + off, in, n);
        in += n;
        len -= n;
        off = 0;
    }

    return len == 0;
}

static size_t iov_total(const struct msghdr *msg)
{
    size_t total = 0;
    size_t i;

    for (i = 0; i < msg->msg_iovlen; ++i) {
        if (SIZE_MAX - total < msg->msg_iov[i].iov_len)
            return 0;
        total += msg->msg_iov[i].iov_len;
    }

    return total;
}

static int read_u32(const struct msghdr *msg, size_t off, uint32_t *value)
{
    return iov_read(msg, off, value, sizeof(*value));
}

static int read_i32(const struct msghdr *msg, size_t off, int32_t *value)
{
    return iov_read(msg, off, value, sizeof(*value));
}

static int write_i32(const struct msghdr *msg, size_t off, int32_t value)
{
    return iov_write(msg, off, &value, sizeof(value));
}

static size_t align4(size_t n)
{
    return (n + 3u) & ~3u;
}

static void clamp_pair(const struct msghdr *msg, size_t width_off,
                       size_t height_off, const char *kind, uint32_t id)
{
    int32_t w, h, nw, nh;

    if (!read_i32(msg, width_off, &w) ||
        !read_i32(msg, height_off, &h))
        return;

    nw = w > 0 ? w : 1;
    nh = h > 0 ? h : 1;

    if (nw == w && nh == h)
        return;

    if (write_i32(msg, width_off, nw) &&
        write_i32(msg, height_off, nh)) {
        (void)kind;
        (void)id;
    }
}

static int read_wire_string(const struct msghdr *msg, size_t off,
                            size_t msg_end, char *dst, size_t dst_size,
                            size_t *next_off)
{
    uint32_t len;
    size_t padded;

    if (!read_u32(msg, off, &len) || len == 0)
        return 0;

    if (off + 4 > msg_end || (size_t)len > msg_end - off - 4)
        return 0;

    padded = align4((size_t)len);
    if (padded > msg_end - off - 4)
        return 0;

    if (dst_size) {
        size_t copy = len;

        if (copy > dst_size - 1)
            copy = dst_size - 1;

        if (copy && !iov_read(msg, off + 4, dst, copy))
            return 0;

        dst[copy] = '\0';
    }

    *next_off = off + 4 + padded;
    return 1;
}

/*
 * Strictly validate a buffer as a sequence of complete Wayland messages.
 * Before an fd is a candidate, we require the canonical first-core request:
 *
 *   wl_display (object 1).get_registry (opcode 1), size 12
 *
 * This makes accidental classification of arbitrary Chromium IPC data
 * extremely unlikely. Even after that, no mutation occurs until an actual
 * wl_registry.bind("xdg_wm_base", ...) is observed.
 */
static int parse_messages(struct fd_state *s, const struct msghdr *msg)
{
    const size_t total = iov_total(msg);
    size_t off = 0;
    int saw_valid_message = 0;

    if (total < 8)
        return 0;

    while (total - off >= 8) {
        uint32_t object_id, word;
        uint16_t opcode, size;
        size_t end;

        if (!read_u32(msg, off, &object_id) ||
            !read_u32(msg, off + 4, &word))
            return saw_valid_message;

        opcode = (uint16_t)(word & 0xffffu);
        size = (uint16_t)(word >> 16);

        if (size < 8 || (size & 3u) || size > total - off)
            return saw_valid_message;

        end = off + size;
        saw_valid_message = 1;

        if (!s->saw_registry_request) {
            if (object_id == 1 && opcode == 1 && size == 12) {
                uint32_t registry_id;
                if (read_u32(msg, off + 8, &registry_id) &&
                    registry_id >= 2 && registry_id < 0xff000000u) {
                    s->saw_registry_request = 1;
                    idset_add(&s->registries, registry_id);
                }
            }

            off = end;
            continue;
        }

        if (object_id == 1 && opcode == 1 && size == 12) {
            uint32_t registry_id;
            if (read_u32(msg, off + 8, &registry_id))
                idset_add(&s->registries, registry_id);
        }

        if (idset_contains(&s->registries, object_id) &&
            opcode == 0 && size >= 24) {
            char interface_name[64];
            size_t cursor;
            uint32_t new_id;

            if (read_wire_string(msg, off + 12, end,
                                 interface_name, sizeof(interface_name),
                                 &cursor) &&
                cursor + 8 <= end &&
                read_u32(msg, cursor + 4, &new_id) &&
                strcmp(interface_name, "xdg_wm_base") == 0) {
                idset_add(&s->xdg_wm_bases, new_id);
                s->confirmed_xdg_shell = 1;
            }
        }

        if (s->confirmed_xdg_shell &&
            idset_contains(&s->xdg_wm_bases, object_id)) {
            if (opcode == 0 && size == 8) {
                idset_remove(&s->xdg_wm_bases, object_id);
            } else if (opcode == 1 && size == 12) {
                uint32_t id;
                if (read_u32(msg, off + 8, &id))
                    idset_add(&s->xdg_positioners, id);
            } else if (opcode == 2 && size == 16) {
                uint32_t id;
                if (read_u32(msg, off + 8, &id))
                    idset_add(&s->xdg_surfaces, id);
            }
        }

        if (s->confirmed_xdg_shell &&
            idset_contains(&s->xdg_surfaces, object_id)) {
            if (opcode == 0 && size == 8) {
                idset_remove(&s->xdg_surfaces, object_id);
            } else if (opcode == 3 && size == 24) {
                clamp_pair(msg, off + 16, off + 20,
                           "xdg_surface", object_id);
            }
        }

        if (s->confirmed_xdg_shell &&
            idset_contains(&s->xdg_positioners, object_id)) {
            if (opcode == 0 && size == 8) {
                idset_remove(&s->xdg_positioners, object_id);
            } else if (opcode == 1 && size == 16) {
                clamp_pair(msg, off + 8, off + 12,
                           "xdg_positioner.set_size", object_id);
            } else if (opcode == 2 && size == 24) {
                clamp_pair(msg, off + 16, off + 20,
                           "xdg_positioner.set_anchor_rect", object_id);
            }
        }

        off = end;
    }

    return saw_valid_message;
}

ssize_t sendmsg(int fd, const struct msghdr *msg, int flags)
{
    struct fd_state *s;

    pthread_once(&symbols_once, resolve_symbols);

    /*
     * No probing syscalls here. For tiny/non-iovec IPC messages, immediately
     * fall through to libc.
     */
    if (!msg || !msg->msg_iov || msg->msg_iovlen == 0)
        return real_sendmsg(fd, msg, flags);

    pthread_mutex_lock(&states_lock);

    s = find_state_locked(fd);
    if (!s) {
        /*
         * Allocate state lazily only for a buffer that begins with a strictly
         * valid wl_display.get_registry request. This prevents state growth
         * from arbitrary Mojo sockets.
         */
        uint32_t object_id = 0, word = 0, registry_id = 0;
        const size_t total = iov_total(msg);

        if (total >= 12 &&
            read_u32(msg, 0, &object_id) &&
            read_u32(msg, 4, &word) &&
            object_id == 1 &&
            (uint16_t)(word & 0xffffu) == 1 &&
            (uint16_t)(word >> 16) == 12 &&
            read_u32(msg, 8, &registry_id) &&
            registry_id >= 2 &&
            registry_id < 0xff000000u) {
            s = get_state_locked(fd);
        }
    }

    if (s)
        (void)parse_messages(s, msg);

    pthread_mutex_unlock(&states_lock);

    return real_sendmsg(fd, msg, flags);
}

int close(int fd)
{
    pthread_once(&symbols_once, resolve_symbols);

    pthread_mutex_lock(&states_lock);
    remove_state_locked(fd);
    pthread_mutex_unlock(&states_lock);

    return real_close(fd);
}
