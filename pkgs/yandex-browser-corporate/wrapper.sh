#!@bash@/bin/bash

set -euo pipefail

browser_dir=@browser@
license_seed=${YANDEX_LICENSE_SECRET_PATH-}
license_file=${HOME}/.yandex/browser/license
singleton_guard_fd=
profile_dir=${XDG_CONFIG_HOME}/yandex-browser

trap 'exit 130' INT
trap 'exit 143' TERM

# Optional diagnostics.  Launch with YANDEX_BROWSER_WRAPPER_DEBUG=1 to append
# to a log inside the application-private persistent state directory.
wrapper_debug=${YANDEX_BROWSER_WRAPPER_DEBUG-0}
log_dir=${XDG_STATE_HOME}/yandex-browser-corporate
log_file=$log_dir/wrapper.log
dbg() {
    [[ "$wrapper_debug" == 1 ]] || return 0
    @coreutils@/bin/mkdir -p -- "$log_dir"
    printf '%s %s\n' "$(@coreutils@/bin/date +%H:%M:%S)" "$*" >>"$log_file"
}
dbg "launch: browser_dir=$browser_dir"

# The seed remains read-only.  The browser owns and may rotate the private
# profile copy; do not overwrite a non-empty copy on later launches.
if [[ -n "$license_seed" && -r "$license_seed" && ! -s "$license_file" ]]; then
    dbg "seeding license copy from $license_seed"
    @coreutils@/bin/install -Dm600 "$license_seed" "$license_file"
elif [[ -n "$license_seed" && ! -r "$license_seed" ]]; then
    dbg "warning: license seed $license_seed is not readable"
fi

# PID namespaces give the browser the same small PID on every invocation.
# Chromium's hostname-PID SingletonLock can therefore look live after a hard
# kill.  This advisory lock lives in the application-private shared /tmp and
# tells a real concurrent invocation apart from stale Chromium state.
exec {singleton_guard_fd}>/tmp/.yandex-browser-wrapper.lock
if @flock@ --nonblock "$singleton_guard_fd"; then
    dbg "primary instance: clearing stale single-instance state"
    @coreutils@/bin/rm -f -- \
        "$profile_dir/SingletonCookie" \
        "$profile_dir/SingletonLock" \
        "$profile_dir/SingletonSocket"

    shopt -s nullglob
    stale_runtime_paths=(
        /tmp/.ru.yandex.desktop.browser.*
    )
    shopt -u nullglob
    for stale_path in "${stale_runtime_paths[@]}"; do
        @coreutils@/bin/rm -rf --one-file-system -- "$stale_path"
    done
else
    # Let the primary instance publish its socket before Chromium attempts to
    # forward this invocation's URLs to it.  Ten seconds covers cold starts;
    # exceeding it means forwarding will fail, so say so out loud.
    socket_ready=no
    for _attempt in {1..1000}; do
        if [[ -L "$profile_dir/SingletonSocket" ]]; then
            socket_ready=yes
            break
        fi
        @coreutils@/bin/sleep 0.01
    done
    if [[ "$socket_ready" == yes ]]; then
        dbg "secondary instance: primary socket appeared"
    else
        dbg "secondary instance: primary socket missing after 10 s"
        printf 'yandex-browser-corporate: primary instance did not publish its socket within 10 s\n' >&2
    fi
fi

# Prefer cursor settings explicitly exported by the compositor session. KDE
# normally exposes them through the Settings portal instead, so query it with
# a short timeout. The derivation supplies only the search path containing a
# fallback cursor package; it never fixes the active theme.
cursor_theme=${XCURSOR_THEME-}
cursor_size=${XCURSOR_SIZE-}

if [[ -z "$cursor_theme" && -n ${DBUS_SESSION_BUS_ADDRESS-} ]]; then
    if cursor_reply=$(@coreutils@/bin/timeout 2 \
        @gdbus@ call --session \
        --dest org.freedesktop.portal.Desktop \
        --object-path /org/freedesktop/portal/desktop \
        --method org.freedesktop.portal.Settings.Read \
        org.gnome.desktop.interface cursor-theme 2>/dev/null); then
        cursor_theme_pattern="<<'([^']+)'>>"
        if [[ $cursor_reply =~ $cursor_theme_pattern ]]; then
            cursor_theme=${BASH_REMATCH[1]}
        fi
    fi
fi

if [[ -z "$cursor_size" && -n ${DBUS_SESSION_BUS_ADDRESS-} ]]; then
    if cursor_reply=$(@coreutils@/bin/timeout 2 \
        @gdbus@ call --session \
        --dest org.freedesktop.portal.Desktop \
        --object-path /org/freedesktop/portal/desktop \
        --method org.freedesktop.portal.Settings.Read \
        org.gnome.desktop.interface cursor-size 2>/dev/null); then
        cursor_size_pattern='<<([1-9][0-9]*)>>'
        if [[ $cursor_reply =~ $cursor_size_pattern ]]; then
            cursor_size=${BASH_REMATCH[1]}
        fi
    fi
fi
dbg "cursor: theme=${cursor_theme-<unset>} size=${cursor_size-<unset>}"

export XCURSOR_PATH=@cursorPath@
export XCURSOR_THEME="$cursor_theme"
export XCURSOR_SIZE="$cursor_size"

# The browser uses direct Wayland, but Yandex 26.4 occasionally emits an
# xdg_surface.set_window_geometry request with a 0x0 size. Chromium can bundle
# its own hidden libwayland-client, so sanitize the final Wayland wire stream
# rather than replacing the public libwayland-client.
export LD_PRELOAD="@waylandWireSanitizer@/lib/libyandex-wayland-wire-sanitizer.so${LD_PRELOAD:+:$LD_PRELOAD}"

browser_args=(
    # Native Wayland/GBM directly to the host compositor socket.
    --ozone-platform=wayland

    --qt-version=6
    --password-store=@passwordStore@
    --class=@appId@
    @extraArgs@
)

set +e
(
    exec -a "$browser_dir/yandex-browser" \
        "$browser_dir/yandex-browser" "${browser_args[@]}" "$@"
) &
browser_pid=$!
wait "$browser_pid"
browser_status=$?
set -e
dbg "exit: status=$browser_status"

exit "$browser_status"
