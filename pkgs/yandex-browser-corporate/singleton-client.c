#define _GNU_SOURCE

#include <errno.h>
#include <poll.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/socket.h>
#include <sys/un.h>
#include <time.h>
#include <unistd.h>

/*
 * Hands a launch over to the running browser through its SingletonSocket,
 * exactly like Chromium's own ProcessSingleton client
 * (chrome/browser/process_singleton_posix.cc): send
 * "START\0<cwd>\0<argv0>\0<arg>...", shut down the write side, then read
 * "ACK" (delivered) or "SHUTDOWN" (the other instance is exiting).
 *
 * Chromium's client cannot be used for this inside per-launch PID
 * namespaces: every browser there is PID 2, so when the running instance is
 * slow to answer, the newcomer takes its SingletonLock ("<host>-2") for its
 * own stale lock and opens the same profile a second time.
 *
 * Usage: singleton-client SOCKET ARGV0 [ARG...]
 * Exit:  0 delivered
 *        2 nobody listening yet, or the other side is shutting down (retry)
 *        1 connected but no answer within 20 s (Chromium's timeout), or error
 */

#define ACK_TIMEOUT_MS 20000

static int write_all(int fd, const char *buf, size_t len)
{
    while (len) {
        ssize_t n = write(fd, buf, len);
        if (n < 0) {
            if (errno == EINTR)
                continue;
            return -1;
        }
        buf += n;
        len -= (size_t)n;
    }
    return 0;
}

static long long now_ms(void)
{
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    return (long long)ts.tv_sec * 1000 + ts.tv_nsec / 1000000;
}

int main(int argc, char **argv)
{
    struct sockaddr_un addr = { .sun_family = AF_UNIX };
    char *cwd, *message, *p;
    char reply[16];
    size_t len, got = 0;
    long long deadline;
    int fd, i;

    if (argc < 3) {
        fprintf(stderr, "usage: %s SOCKET ARGV0 [ARG...]\n", argv[0]);
        return 1;
    }
    if (strlen(argv[1]) >= sizeof(addr.sun_path)) {
        fprintf(stderr, "singleton-client: socket path too long\n");
        return 1;
    }
    strcpy(addr.sun_path, argv[1]);

    fd = socket(AF_UNIX, SOCK_STREAM | SOCK_CLOEXEC, 0);
    if (fd < 0) {
        perror("singleton-client: socket");
        return 1;
    }
    if (connect(fd, (struct sockaddr *)&addr, sizeof(addr)) < 0) {
        /* Not created yet, or a stale symlink/socket: the owner is still
         * starting up or already gone. */
        if (errno == ENOENT || errno == ECONNREFUSED || errno == ENOTDIR)
            return 2;
        perror("singleton-client: connect");
        return 1;
    }

    cwd = getcwd(NULL, 0);
    if (!cwd)
        cwd = strdup("/");
    if (!cwd)
        return 1;

    len = strlen("START") + 1 + strlen(cwd);
    for (i = 2; i < argc; ++i)
        len += 1 + strlen(argv[i]);
    message = malloc(len);
    if (!message)
        return 1;

    p = stpcpy(message, "START") + 1;
    p = stpcpy(p, cwd);
    for (i = 2; i < argc; ++i)
        p = stpcpy(p + 1, argv[i]);

    if (write_all(fd, message, len) < 0 || shutdown(fd, SHUT_WR) < 0) {
        perror("singleton-client: write");
        return 1;
    }

    deadline = now_ms() + ACK_TIMEOUT_MS;
    while (got < sizeof(reply) - 1) {
        struct pollfd pfd = { .fd = fd, .events = POLLIN };
        long long left = deadline - now_ms();
        ssize_t n;
        int ready;

        if (left <= 0)
            break;
        ready = poll(&pfd, 1, (int)left);
        if (ready < 0 && errno == EINTR)
            continue;
        if (ready <= 0)
            break;
        n = read(fd, reply + got, sizeof(reply) - 1 - got);
        if (n < 0 && errno == EINTR)
            continue;
        if (n <= 0)
            break;
        got += (size_t)n;
        reply[got] = '\0';
        if (strncmp(reply, "ACK", 3) == 0 && got >= 3)
            return 0;
        if (strncmp(reply, "SHUTDOWN", 8) == 0 && got >= 8)
            return 2;
    }

    reply[got] = '\0';
    if (strncmp(reply, "ACK", 3) == 0 && got >= 3)
        return 0;
    if (strncmp(reply, "SHUTDOWN", 8) == 0 && got >= 8)
        return 2;
    return 1;
}
