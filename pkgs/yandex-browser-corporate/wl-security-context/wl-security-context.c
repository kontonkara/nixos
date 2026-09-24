#define _GNU_SOURCE

/*
 * wl-security-context: run a command on a restricted Wayland socket.
 *
 *   wl-security-context --app-id ID --instance-id ID [--engine NAME]
 *                       --socket NAME -- COMMAND [ARGS...]
 *
 * Creates a listening socket at $XDG_RUNTIME_DIR/NAME, registers it with the
 * compositor through wp_security_context_manager_v1 (security-context-v1),
 * and runs COMMAND with WAYLAND_DISPLAY=NAME. Every client that connects
 * through NAME is tagged with the security context; niri hides privileged
 * globals (screencopy, data-control, layer-shell, virtual input,
 * foreign-toplevel, output-management, session-lock, input-method, ...) from
 * such clients.
 *
 * Lifetime: the compositor accepts connections on NAME until the write end of
 * the close_fd pipe is closed. This process holds it until COMMAND exits,
 * then removes the socket file (and its NAME.lock). Connections that were
 * already established are not affected; the compositor only stops accepting
 * new ones.
 *
 * If the compositor does not offer the global (unsupported, or we are already
 * inside a security context, where nesting is forbidden) this is a hard
 * error: silently handing COMMAND an unrestricted socket would defeat the
 * point.
 */

#include <errno.h>
#include <fcntl.h>
#include <signal.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/file.h>
#include <sys/socket.h>
#include <sys/stat.h>
#include <sys/un.h>
#include <sys/wait.h>
#include <unistd.h>

#include <wayland-client.h>

#include "security-context-v1-client-protocol.h"

#define PROG "wl-security-context"
#define DEFAULT_ENGINE "nixpak"
#define LOCK_SUFFIX ".lock"

struct options {
    const char *app_id;
    const char *instance_id;
    const char *engine;
    const char *socket_name;
    char **command;
};

/* Files this process created and must remove before exiting. */
static struct {
    char socket_path[sizeof(((struct sockaddr_un *)0)->sun_path)];
    char lock_path[sizeof(((struct sockaddr_un *)0)->sun_path) + sizeof LOCK_SUFFIX];
    bool socket_created;
    int lock_fd;
} files = { .lock_fd = -1 };

static void cleanup_files(void)
{
    if (files.socket_created) {
        unlink(files.socket_path);
        files.socket_created = false;
    }
    /* Same order as libwayland: drop the socket first, then the lock. */
    if (files.lock_fd >= 0) {
        unlink(files.lock_path);
        close(files.lock_fd);
        files.lock_fd = -1;
    }
}

static void usage(FILE *out)
{
    fprintf(out,
            "Usage: " PROG " --app-id ID --instance-id ID [--engine NAME]\n"
            "           --socket NAME -- COMMAND [ARGS...]\n"
            "\n"
            "Create $XDG_RUNTIME_DIR/NAME as a wp_security_context_v1 listener\n"
            "and run COMMAND with WAYLAND_DISPLAY=NAME.\n"
            "\n"
            "  --app-id ID        application ID attached to the context\n"
            "  --instance-id ID   instance ID attached to the context\n"
            "  --engine NAME      sandbox engine name (default: " DEFAULT_ENGINE ")\n"
            "  --socket NAME      socket file name inside $XDG_RUNTIME_DIR\n");
}

static void usage_error(const char *fmt, const char *arg)
{
    fprintf(stderr, PROG ": ");
    fprintf(stderr, fmt, arg);
    fputc('\n', stderr);
    usage(stderr);
    exit(2);
}

/* Matches "--name VALUE" or "--name=VALUE" at argv[*i]. */
static bool take_option(const char *name, int argc, char **argv, int *i,
                        const char **value)
{
    const char *arg = argv[*i];
    size_t len = strlen(name);

    if (strncmp(arg, name, len) != 0)
        return false;
    if (arg[len] == '=') {
        *value = arg + len + 1;
        return true;
    }
    if (arg[len] != '\0')
        return false;
    if (*i + 1 >= argc)
        usage_error("option '%s' needs a value", name);
    *value = argv[++*i];
    return true;
}

/* Options, then "--", then COMMAND. */
static void parse_args(int argc, char **argv, struct options *opts)
{
    int i = 1;
    for (; i < argc; i++) {
        const char *arg = argv[i];
        if (strcmp(arg, "--") == 0) {
            i++;
            break;
        }
        if (strcmp(arg, "--help") == 0 || strcmp(arg, "-h") == 0) {
            usage(stdout);
            exit(0);
        }
        if (take_option("--app-id", argc, argv, &i, &opts->app_id) ||
            take_option("--instance-id", argc, argv, &i, &opts->instance_id) ||
            take_option("--engine", argc, argv, &i, &opts->engine) ||
            take_option("--socket", argc, argv, &i, &opts->socket_name))
            continue;
        usage_error("unknown argument '%s'", arg);
    }

    if (i >= argc)
        usage_error("%s", "missing '-- COMMAND'");
    opts->command = &argv[i];

    if (!opts->app_id || !*opts->app_id)
        usage_error("%s", "--app-id is required");
    if (!opts->instance_id || !*opts->instance_id)
        usage_error("%s", "--instance-id is required");
    if (!opts->engine)
        opts->engine = DEFAULT_ENGINE;
    if (!*opts->engine)
        usage_error("%s", "--engine must not be empty");

    /* NAME ends up in WAYLAND_DISPLAY, which libwayland resolves relative
     * to XDG_RUNTIME_DIR, so it has to be a plain file name. */
    const char *name = opts->socket_name;
    if (!name || !*name)
        usage_error("%s", "--socket is required");
    if (strchr(name, '/') || strcmp(name, ".") == 0 || strcmp(name, "..") == 0)
        usage_error("--socket must be a plain file name, not '%s'", name);
}

/* Registry: we only care about the security context manager. */

static void registry_global(void *data, struct wl_registry *registry,
                            uint32_t name, const char *interface,
                            uint32_t version)
{
    struct wp_security_context_manager_v1 **manager = data;
    (void)version;

    if (!*manager &&
        strcmp(interface, wp_security_context_manager_v1_interface.name) == 0)
        *manager = wl_registry_bind(registry, name,
                                    &wp_security_context_manager_v1_interface, 1);
}

static void registry_global_remove(void *data, struct wl_registry *registry,
                                   uint32_t name)
{
    (void)data;
    (void)registry;
    (void)name;
}

static const struct wl_registry_listener registry_listener = {
    .global = registry_global,
    .global_remove = registry_global_remove,
};

/* Report a failed round-trip, including protocol error details. */
static void report_display_error(struct wl_display *display, const char *what)
{
    int err = wl_display_get_error(display);

    if (err == EPROTO) {
        const struct wl_interface *iface = NULL;
        uint32_t id = 0;
        uint32_t code = wl_display_get_protocol_error(display, &iface, &id);
        fprintf(stderr, PROG ": %s: protocol error %u on %s@%u\n", what, code,
                iface ? iface->name : "<unknown>", id);
    } else {
        fprintf(stderr, PROG ": %s: %s\n", what, strerror(err));
    }
}

/*
 * Serialise concurrent instances that use the same NAME (libwayland's
 * NAME.lock convention, which also keeps us off a compositor's own socket).
 * While we hold the lock, the stale-socket check below cannot race with
 * another instance that is between bind() and listen().
 */
static bool lock_socket_name(void)
{
    files.lock_fd = open(files.lock_path, O_RDWR | O_CREAT | O_CLOEXEC | O_NOFOLLOW,
                         0600);
    if (files.lock_fd < 0) {
        fprintf(stderr, PROG ": cannot open %s: %s\n", files.lock_path,
                strerror(errno));
        return false;
    }
    if (flock(files.lock_fd, LOCK_EX | LOCK_NB) < 0) {
        if (errno == EWOULDBLOCK)
            fprintf(stderr, PROG ": %s is in use by another process\n",
                    files.socket_path);
        else
            fprintf(stderr, PROG ": cannot lock %s: %s\n", files.lock_path,
                    strerror(errno));
        close(files.lock_fd); /* not ours: must not unlink it */
        files.lock_fd = -1;
        return false;
    }
    return true;
}

/*
 * Something already exists at the socket path. Remove it only if it is a
 * socket nobody listens on (left behind by a crashed run: once its close_fd
 * pipe hung up the compositor dropped the listener); never touch a live
 * socket or a non-socket file.
 */
static bool remove_stale_socket(const struct sockaddr_un *addr)
{
    struct stat st;
    if (lstat(addr->sun_path, &st) < 0)
        return errno == ENOENT; /* vanished in the meantime: just retry */
    if (!S_ISSOCK(st.st_mode)) {
        fprintf(stderr, PROG ": %s exists and is not a socket\n", addr->sun_path);
        return false;
    }

    int probe = socket(AF_UNIX, SOCK_STREAM | SOCK_CLOEXEC, 0);
    if (probe < 0) {
        fprintf(stderr, PROG ": socket: %s\n", strerror(errno));
        return false;
    }
    int rc = connect(probe, (const struct sockaddr *)addr, sizeof *addr);
    int err = errno;
    close(probe);

    if (rc == 0) {
        fprintf(stderr, PROG ": %s is already in use\n", addr->sun_path);
        return false;
    }
    if (err != ECONNREFUSED) {
        fprintf(stderr, PROG ": cannot probe existing %s: %s\n", addr->sun_path,
                strerror(err));
        return false;
    }
    if (unlink(addr->sun_path) < 0 && errno != ENOENT) {
        fprintf(stderr, PROG ": cannot remove stale %s: %s\n", addr->sun_path,
                strerror(errno));
        return false;
    }
    return true;
}

static int create_listen_socket(void)
{
    struct sockaddr_un addr = { .sun_family = AF_UNIX };
    memcpy(addr.sun_path, files.socket_path, sizeof addr.sun_path);

    int fd = socket(AF_UNIX, SOCK_STREAM | SOCK_CLOEXEC, 0);
    if (fd < 0) {
        fprintf(stderr, PROG ": socket: %s\n", strerror(errno));
        return -1;
    }

    int rc = bind(fd, (struct sockaddr *)&addr, sizeof addr);
    if (rc < 0 && errno == EADDRINUSE) {
        if (!remove_stale_socket(&addr))
            goto fail;
        rc = bind(fd, (struct sockaddr *)&addr, sizeof addr);
    }
    if (rc < 0) {
        fprintf(stderr, PROG ": cannot bind %s: %s\n", files.socket_path,
                strerror(errno));
        goto fail;
    }
    files.socket_created = true;

    if (listen(fd, 128) < 0) {
        fprintf(stderr, PROG ": listen: %s\n", strerror(errno));
        goto fail;
    }
    return fd;

fail:
    close(fd);
    return -1;
}

/*
 * Register the listener with the compositor. On success returns the write end
 * of the close_fd pipe, which must stay open for as long as new connections
 * should be accepted.
 */
static int register_security_context(const struct options *opts)
{
    struct wl_display *display = wl_display_connect(NULL);
    if (!display) {
        fprintf(stderr, PROG ": cannot connect to the Wayland compositor: %s\n",
                strerror(errno));
        return -1;
    }

    struct wp_security_context_manager_v1 *manager = NULL;
    struct wl_registry *registry = wl_display_get_registry(display);
    wl_registry_add_listener(registry, &registry_listener, &manager);
    if (wl_display_roundtrip(display) < 0) {
        report_display_error(display, "registry round-trip failed");
        goto fail_display;
    }
    if (!manager) {
        fprintf(stderr,
                PROG ": compositor does not offer %s (unsupported, or this "
                "process already runs inside a security context); refusing to "
                "run without restrictions\n",
                wp_security_context_manager_v1_interface.name);
        goto fail_display;
    }

    if (!lock_socket_name())
        goto fail_display;
    int listen_fd = create_listen_socket();
    if (listen_fd < 0)
        goto fail_display;

    int close_pipe[2];
    if (pipe2(close_pipe, O_CLOEXEC) < 0) {
        fprintf(stderr, PROG ": pipe2: %s\n", strerror(errno));
        close(listen_fd);
        goto fail_display;
    }

    /* libwayland dup()s both fds while marshalling, so ours can be closed
     * right after the request has been queued. */
    struct wp_security_context_v1 *context =
        wp_security_context_manager_v1_create_listener(manager, listen_fd,
                                                       close_pipe[0]);
    close(listen_fd);
    close(close_pipe[0]);

    wp_security_context_v1_set_sandbox_engine(context, opts->engine);
    wp_security_context_v1_set_app_id(context, opts->app_id);
    wp_security_context_v1_set_instance_id(context, opts->instance_id);
    wp_security_context_v1_commit(context);

    if (wl_display_roundtrip(display) < 0) {
        report_display_error(display, "cannot create security context");
        close(close_pipe[1]);
        goto fail_display;
    }

    /*
     * The creating connection is not needed any more. security-context-v1
     * requires the compositor to keep accepting on listen_fd after the
     * creating client disconnects, and niri does so: the listener lives in
     * niri's event loop until close_fd hangs up. Verified empirically with
     * niri unstable 2026-08-02 (feb3e43f): a client connecting via NAME 2 s
     * after this disconnect gets the restricted global list, and once the
     * close_fd writer dies, connecting to NAME fails with ECONNREFUSED.
     * Disconnecting also guarantees COMMAND never sees this unrestricted
     * connection.
     */
    wp_security_context_v1_destroy(context);
    wp_security_context_manager_v1_destroy(manager);
    wl_registry_destroy(registry);
    wl_display_flush(display);
    wl_display_disconnect(display);

    return close_pipe[1];

fail_display:
    wl_display_disconnect(display);
    return -1;
}

static int exit_code(int status)
{
    if (WIFEXITED(status))
        return WEXITSTATUS(status);
    if (WIFSIGNALED(status))
        return 128 + WTERMSIG(status);
    return 1;
}

/*
 * Wait for the child, forwarding termination signals. All relevant signals
 * are blocked and consumed synchronously with sigwaitinfo(), so there are no
 * handlers, no races with SIGCHLD and no polling.
 */
static int supervise(pid_t child, const sigset_t *signals)
{
    for (;;) {
        siginfo_t info;
        int sig = sigwaitinfo(signals, &info);
        if (sig < 0) {
            if (errno == EINTR)
                continue;
            fprintf(stderr, PROG ": sigwaitinfo: %s\n", strerror(errno));
            break;
        }

        if (sig == SIGCHLD) {
            int status;
            pid_t pid = waitpid(child, &status, WNOHANG);
            if (pid == child)
                return exit_code(status);
            if (pid < 0 && errno != EINTR) {
                fprintf(stderr, PROG ": waitpid: %s\n", strerror(errno));
                return 1;
            }
            continue;
        }

        /*
         * Terminal-generated signals (Ctrl-C, tty hangup) are sent by the
         * kernel to the whole foreground process group. If the child still
         * shares our group it already got its own copy; forwarding it would
         * deliver it twice, and Chromium treats a second SIGINT/SIGTERM as
         * "skip graceful shutdown".
         */
        if (info.si_code == SI_KERNEL && getpgid(child) == getpgrp())
            continue;
        kill(child, sig);
    }

    /* Fallback if sigwaitinfo() ever fails: plain blocking wait. */
    int status;
    while (waitpid(child, &status, 0) < 0) {
        if (errno != EINTR) {
            fprintf(stderr, PROG ": waitpid: %s\n", strerror(errno));
            return 1;
        }
    }
    return exit_code(status);
}

int main(int argc, char **argv)
{
    struct options opts = { 0 };
    parse_args(argc, argv, &opts);

    const char *runtime_dir = getenv("XDG_RUNTIME_DIR");
    if (!runtime_dir || runtime_dir[0] != '/') {
        fprintf(stderr, PROG ": XDG_RUNTIME_DIR is not set to an absolute path\n");
        return 1;
    }
    int n = snprintf(files.socket_path, sizeof files.socket_path, "%s/%s",
                     runtime_dir, opts.socket_name);
    if (n < 0 || (size_t)n >= sizeof files.socket_path) {
        fprintf(stderr, PROG ": socket path %s/%s is too long\n", runtime_dir,
                opts.socket_name);
        return 1;
    }
    snprintf(files.lock_path, sizeof files.lock_path, "%s" LOCK_SUFFIX,
             files.socket_path);

    /* An inherited SIG_IGN would make the kernel auto-reap the child and
     * waitpid() fail with ECHILD. */
    signal(SIGCHLD, SIG_DFL);

    int close_fd_writer = register_security_context(&opts);
    if (close_fd_writer < 0) {
        cleanup_files();
        return 1;
    }

    sigset_t signals, old_mask;
    sigemptyset(&signals);
    sigaddset(&signals, SIGCHLD);
    sigaddset(&signals, SIGTERM);
    sigaddset(&signals, SIGINT);
    sigaddset(&signals, SIGHUP);
    sigprocmask(SIG_BLOCK, &signals, &old_mask);

    pid_t child = fork();
    if (child < 0) {
        fprintf(stderr, PROG ": fork: %s\n", strerror(errno));
        close(close_fd_writer);
        cleanup_files();
        return 1;
    }

    if (child == 0) {
        /* Every fd we own is O_CLOEXEC, so only stdio etc. is inherited. */
        sigprocmask(SIG_SETMASK, &old_mask, NULL);
        /* WAYLAND_SOCKET takes precedence over WAYLAND_DISPLAY in libwayland
         * and would bypass the restricted socket. */
        unsetenv("WAYLAND_SOCKET");
        if (setenv("WAYLAND_DISPLAY", opts.socket_name, 1) < 0) {
            fprintf(stderr, PROG ": setenv: %s\n", strerror(errno));
            _exit(127);
        }
        execvp(opts.command[0], opts.command);
        int err = errno;
        fprintf(stderr, PROG ": cannot execute %s: %s\n", opts.command[0],
                strerror(err));
        _exit(err == ENOENT ? 127 : 126);
    }

    int code = supervise(child, &signals);

    /* Hang up close_fd first so the compositor stops accepting, then remove
     * the socket file. */
    close(close_fd_writer);
    cleanup_files();
    return code;
}
