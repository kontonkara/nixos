#define _GNU_SOURCE

#include <dlfcn.h>
#include <errno.h>
#include <fcntl.h>
#include <pthread.h>
#include <stdatomic.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/socket.h>
#include <sys/types.h>
#include <sys/uio.h>
#include <unistd.h>

/*
 * Yandex Browser Corporate native-Wayland geometry sanitizer.
 *
 * Yandex's custom titlebar sends xdg_surface.set_window_geometry (and
 * xdg_positioner sizes) of 0x0. The xdg-shell spec makes that an
 * invalid_size protocol error, and compositors that enforce it (KWin,
 * Smithay-based niri) disconnect the client, killing the browser.
 *
 * Chromium bundles its own hidden libwayland-client, so patching the public
 * libwayland-client does not affect Ozone. The interposer performs NO
 * socket-probing syscalls and does not interpose connect(). On sendmsg() it
 * only inspects the already-present userspace iovec bytes. An fd becomes a
 * Wayland candidate only after an exact wl_display.get_registry(new_id)
 * request is observed. It becomes useful for mutation only after that
 * registry subsequently binds "xdg_wm_base" and creates the corresponding
 * xdg_surface/xdg_positioner object IDs.
 *
 * Unrelated Chromium Mojo/IPC sockets are passed to the real sendmsg()
 * unchanged. No Wayland proxy is introduced; DMA-BUF, explicit sync, input,
 * buffers, app_id, etc. still go directly to the compositor.
 *
 * Only the browser process owns the Wayland connection. LD_PRELOAD has to
 * stay in the environment (Chromium relaunches itself with its own
 * environment), so every child process loads the library too; there it
 * detects that it isn't the browser and passes calls straight through.
 *
 * Fork safety: Chromium closes every fd, the Wayland socket included, in
 * freshly forked children before exec, and it forks with raw clone() so
 * pthread_atfork handlers don't run. A child must never wait for the lock
 * (another thread may have held it at fork time, and would never release it
 * in the child): all state is owned by the process that loaded us, and any
 * other pid passes straight through. Non-Wayland sendmsg()/close() never
 * take the lock at all, and symbols are resolved without pthread_once
 * (other libraries' constructors may call close() before ours runs).
 *
 * Partial writes: when sendmsg() sends only part of a buffer, libwayland
 * later resends the remainder from its own, unclamped copy, starting in the
 * middle of a message. The rewritten tail of that message is kept per fd and
 * laid over the start of the next sendmsg(), so clamping survives the split.
 */

typedef ssize_t (*sendmsg_fn)(int, const struct msghdr *, int);
typedef int (*close_fn)(int);

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
    /* Rewritten bytes of a message that the last sendmsg() cut short. */
    unsigned char *carry;
    size_t carry_len;
    struct fd_state *next;
};

static pthread_mutex_t states_lock = PTHREAD_MUTEX_INITIALIZER;
static struct fd_state *states;

/* fd + 1 of every tracked connection (0 = free slot), readable without the
 * lock so close() on anything else stays lock-free. A browser has one or two
 * Wayland connections; if the table is full a new one just isn't sanitised. */
#define MAX_TRACKED 8
static atomic_int tracked_fds[MAX_TRACKED];

static int is_tracked(int fd)
{
    int i;
    for (i = 0; i < MAX_TRACKED; ++i)
        if (atomic_load_explicit(&tracked_fds[i], memory_order_acquire) == fd + 1)
            return 1;
    return 0;
}

static int track_fd(int fd)
{
    int i, expected;
    for (i = 0; i < MAX_TRACKED; ++i) {
        expected = 0;
        if (atomic_compare_exchange_strong(&tracked_fds[i], &expected, fd + 1))
            return 1;
    }
    return 0;
}

static void untrack_fd(int fd)
{
    int i, expected;
    for (i = 0; i < MAX_TRACKED; ++i) {
        expected = fd + 1;
        atomic_compare_exchange_strong(&tracked_fds[i], &expected, 0);
    }
}

/* True in every process except the browser itself: zygotes, renderers,
 * GPU/utility processes ("--type=..."), crashpad and anything the browser
 * spawns (xdg-open, update helpers). */
static int passthrough;
/* The process whose Wayland connections we track; forked children differ. */
static pid_t owner_pid;

#define BROWSER_SUFFIX "/yandex_browser"

__attribute__((constructor))
static void detect_role(void)
{
    char buf[4096];
    ssize_t len = 0, n;
    size_t off, arg_len;
    int fd = open("/proc/self/cmdline", O_RDONLY | O_CLOEXEC);

    owner_pid = getpid();
    if (fd < 0)
        return;
    while (len < (ssize_t)sizeof(buf) - 1 &&
           (n = read(fd, buf + len, sizeof(buf) - 1 - (size_t)len)) > 0)
        len += n;
    close(fd);
    buf[len] = '\0';

    /* argv[0] must be the browser binary... */
    arg_len = strlen(buf);
    if (arg_len < sizeof(BROWSER_SUFFIX) - 1 ||
        strcmp(buf + arg_len - (sizeof(BROWSER_SUFFIX) - 1), BROWSER_SUFFIX) != 0) {
        passthrough = 1;
        return;
    }
    /* ...without a child process type. */
    for (off = arg_len + 1; off < (size_t)len; off += strlen(buf + off) + 1) {
        if (strncmp(buf + off, "--type=", 7) == 0) {
            passthrough = 1;
            return;
        }
    }
}

static void reset_lock_in_child(void)
{
    /* Another thread may have held the lock at fork(); only this thread
     * exists in the child. */
    pthread_mutex_init(&states_lock, NULL);
}

/* Idempotent, so a race between threads only repeats harmless work. */
__attribute__((constructor))
static void resolve_symbols(void)
{
    static atomic_int atfork_registered;
    void *sendmsg_sym = dlsym(RTLD_NEXT, "sendmsg");
    void *close_sym = dlsym(RTLD_NEXT, "close");

    if (!sendmsg_sym || !close_sym) {
        const char *e = dlerror();
        dprintf(STDERR_FILENO,
                "yandex-wayland-wire: symbol resolution failed: %s\n",
                e ? e : "unknown error");
        _exit(127);
    }

    __atomic_store_n((void **)&real_sendmsg, sendmsg_sym, __ATOMIC_RELEASE);
    __atomic_store_n((void **)&real_close, close_sym, __ATOMIC_RELEASE);

    if (!atomic_exchange(&atfork_registered, 1))
        pthread_atfork(NULL, NULL, reset_lock_in_child);
}

static sendmsg_fn get_real_sendmsg(void)
{
    sendmsg_fn fn;
    *(void **)&fn = __atomic_load_n((void **)&real_sendmsg, __ATOMIC_ACQUIRE);
    if (!fn) {
        resolve_symbols();
        *(void **)&fn = __atomic_load_n((void **)&real_sendmsg, __ATOMIC_ACQUIRE);
    }
    return fn;
}

static close_fn get_real_close(void)
{
    close_fn fn;
    *(void **)&fn = __atomic_load_n((void **)&real_close, __ATOMIC_ACQUIRE);
    if (!fn) {
        resolve_symbols();
        *(void **)&fn = __atomic_load_n((void **)&real_close, __ATOMIC_ACQUIRE);
    }
    return fn;
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
    if (!track_fd(fd)) {
        free(s);
        return NULL;
    }

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
            free(s->carry);
            free(s);
            untrack_fd(fd);
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
static int parse_messages(struct fd_state *s, const struct msghdr *msg,
                          size_t start)
{
    const size_t total = iov_total(msg);
    size_t off = start;
    int saw_valid_message = 0;

    if (total < start + 8)
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

/* End of the message that contains byte `pos`, walking message headers from
 * `start` (a message boundary). 0 if the stream can't be followed. */
static size_t message_end(const unsigned char *buf, size_t total, size_t start,
                          size_t pos)
{
    size_t off = start;

    while (off + 8 <= total) {
        uint32_t word;
        uint16_t size;

        memcpy(&word, buf + off + 4, sizeof(word));
        size = (uint16_t)(word >> 16);
        if (size < 8 || (size & 3u))
            return 0;
        if (pos < off + size)
            return off + size;
        off += size;
    }
    return 0;
}

/* After a partial send, remember the rewritten remainder of the message it
 * stopped in. Called with the lock held. */
static void remember_carry(struct fd_state *s, const unsigned char *buf,
                           size_t total, size_t start, size_t sent)
{
    size_t end;
    unsigned char *copy;

    if (sent < s->carry_len) {
        /* Still inside the carried message. */
        memmove(s->carry, s->carry + sent, s->carry_len - sent);
        s->carry_len -= sent;
        return;
    }

    s->carry_len = 0;
    if (sent >= total)
        return;

    end = message_end(buf, total, start, sent);
    if (end <= sent || end > total)
        return;

    copy = realloc(s->carry, end - sent);
    if (!copy)
        return;
    memcpy(copy, buf + sent, end - sent);
    s->carry = copy;
    s->carry_len = end - sent;
}

ssize_t sendmsg(int fd, const struct msghdr *msg, int flags)
{
    struct fd_state *s;
    struct msghdr rewritten;
    struct iovec rewritten_iov;
    unsigned char *buffer = NULL;
    size_t total = 0, start = 0;
    ssize_t result;
    int saved_errno;

    /*
     * No probing syscalls here. For tiny/non-iovec IPC messages, immediately
     * fall through to libc.
     */
    if (passthrough || !msg || !msg->msg_iov || msg->msg_iovlen == 0)
        return get_real_sendmsg()(fd, msg, flags);

    if (!is_tracked(fd)) {
        /*
         * Start tracking only a buffer that begins with a strictly valid
         * wl_display.get_registry request; everything else (Mojo IPC, the
         * bulk of all sendmsg calls) goes straight through without the lock.
         */
        uint32_t object_id = 0, word = 0, registry_id = 0;

        total = iov_total(msg);
        if (!(total >= 12 &&
              read_u32(msg, 0, &object_id) &&
              read_u32(msg, 4, &word) &&
              object_id == 1 &&
              (uint16_t)(word & 0xffffu) == 1 &&
              (uint16_t)(word >> 16) == 12 &&
              read_u32(msg, 8, &registry_id) &&
              registry_id >= 2 &&
              registry_id < 0xff000000u))
            return get_real_sendmsg()(fd, msg, flags);
    }
    if (getpid() != owner_pid)
        return get_real_sendmsg()(fd, msg, flags);

    pthread_mutex_lock(&states_lock);

    s = get_state_locked(fd);

    if (s) {
        total = iov_total(msg);

        if (total) {
            /* sendmsg's input may be read-only or shared with another caller.
             * Preserve it, including the original iovec layout, and rewrite
             * only our private payload. Ancillary data and flags stay intact. */
            buffer = malloc(total);
            if (!buffer) {
                pthread_mutex_unlock(&states_lock);
                errno = ENOMEM;
                return -1;
            }
            if (!iov_read(msg, 0, buffer, total)) {
                free(buffer);
                pthread_mutex_unlock(&states_lock);
                errno = EFAULT;
                return -1;
            }

            /* The buffer starts with the rest of a message we already
             * rewrote: lay our version over libwayland's. */
            start = s->carry_len < total ? s->carry_len : total;
            if (start)
                memcpy(buffer, s->carry, start);

            rewritten = *msg;
            rewritten_iov.iov_base = buffer;
            rewritten_iov.iov_len = total;
            rewritten.msg_iov = &rewritten_iov;
            rewritten.msg_iovlen = 1;
            msg = &rewritten;
            (void)parse_messages(s, msg, start);
        }
    }

    pthread_mutex_unlock(&states_lock);

    result = get_real_sendmsg()(fd, msg, flags);
    saved_errno = errno;

    if (buffer && result >= 0) {
        pthread_mutex_lock(&states_lock);
        s = find_state_locked(fd);
        if (s)
            remember_carry(s, buffer, total, start, (size_t)result);
        pthread_mutex_unlock(&states_lock);
    }

    free(buffer);
    errno = saved_errno;
    return result;
}

int close(int fd)
{
    /* Lock-free for everything but tracked Wayland connections: this also
     * runs in forked children that are about to exec. */
    if (!passthrough && is_tracked(fd) && getpid() == owner_pid) {
        pthread_mutex_lock(&states_lock);
        remove_state_locked(fd);
        pthread_mutex_unlock(&states_lock);
    }

    return get_real_close()(fd);
}
