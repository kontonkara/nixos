#!@bash@/bin/bash

set -euo pipefail

browser_dir=@browser@
license_seed=${YANDEX_LICENSE_SECRET_PATH-}
license_file=${HOME}/.yandex/browser/license
inner_proxy_pid=
inner_proxy_dir=
inner_wayland_socket=
singleton_guard_fd=
profile_dir=${XDG_CONFIG_HOME}/yandex-browser

cleanup() {
    if [[ -n "$inner_proxy_pid" ]]; then
        kill "$inner_proxy_pid" 2>/dev/null || true
        wait "$inner_proxy_pid" 2>/dev/null || true
    fi
    if [[ "$inner_proxy_dir" == /tmp/yandex-browser-wayland.* ]]; then
        @coreutils@/bin/rm -rf --one-file-system -- "$inner_proxy_dir"
    fi
}

trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

# The seed remains read-only.  The browser owns and may rotate the private
# profile copy; do not overwrite a non-empty copy on later launches.
if [[ -n "$license_seed" && -r "$license_seed" && ! -s "$license_file" ]]; then
    @coreutils@/bin/install -Dm600 "$license_seed" "$license_file"
fi

# PID namespaces give the browser the same small PID on every invocation.
# Chromium's hostname-PID SingletonLock can therefore look live after a hard
# kill.  This advisory lock lives in the application-private shared /tmp and
# tells a real concurrent invocation apart from stale Chromium state.
exec {singleton_guard_fd}>/tmp/.yandex-browser-wrapper.lock
if @flock@ --nonblock "$singleton_guard_fd"; then
    @coreutils@/bin/rm -f -- \
        "$profile_dir/SingletonCookie" \
        "$profile_dir/SingletonLock" \
        "$profile_dir/SingletonSocket"

    shopt -s nullglob
    stale_runtime_paths=(
        /tmp/.ru.yandex.desktop.browser.*
        /tmp/yandex-browser-wayland.*
    )
    shopt -u nullglob
    for stale_path in "${stale_runtime_paths[@]}"; do
        case "$stale_path" in
            /tmp/.ru.yandex.desktop.browser.*|/tmp/yandex-browser-wayland.*)
                @coreutils@/bin/rm -rf --one-file-system -- "$stale_path"
                ;;
        esac
    done
else
    # Let the primary instance publish its socket before Chromium attempts to
    # forward this invocation's URLs to it.
    for _attempt in {1..500}; do
        if [[ -L "$profile_dir/SingletonSocket" ]]; then
            break
        fi
        @coreutils@/bin/sleep 0.01
    done
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

export XCURSOR_PATH=@cursorPath@
export XCURSOR_THEME="$cursor_theme"
export XCURSOR_SIZE="$cursor_size"

browser_args=(
    --ozone-platform=x11
    --qt-version=6
    --password-store=basic
    --class=@appId@
    @extraArgs@
)

inner_proxy_dir=$(@coreutils@/bin/mktemp -d /tmp/yandex-browser-wayland.XXXXXX)
inner_wayland_socket="$inner_proxy_dir/socket"

inner_proxy_args=(
    --wayland-display="$inner_wayland_socket"
    --x-display=42
    --xwayland-binary=@xwayland@
    --tag=
)
if [[ -n "$cursor_theme" ]]; then
    inner_proxy_args+=(--xrdb="Xcursor.theme: $cursor_theme")
fi
if [[ -n "$cursor_size" ]]; then
    inner_proxy_args+=(--xrdb="Xcursor.size: $cursor_size")
fi

XCURSOR_PATH=@cursorPath@ \
XCURSOR_THEME="$cursor_theme" \
XCURSOR_SIZE="$cursor_size" \
WAYLAND_PROXY_APP_ID=@appId@ \
@waylandProxy@/bin/wayland-proxy-virtwl "${inner_proxy_args[@]}" &
inner_proxy_pid=$!

for _attempt in {1..500}; do
    if [[ -S "$inner_wayland_socket" ]]; then
        break
    fi
    if ! kill -0 "$inner_proxy_pid" 2>/dev/null; then
        wait "$inner_proxy_pid"
        exit $?
    fi
    @coreutils@/bin/sleep 0.01
done

if [[ ! -S "$inner_wayland_socket" ]]; then
    printf 'Yandex Browser: isolated Xwayland proxy did not become ready\n' >&2
    exit 1
fi

# The proxy's --xrdb arguments publish the session selection through the X11
# RESOURCE_MANAGER property. Set the Xwayland root cursor as well, because its
# initial core-X11 cursor otherwise ignores that database.
cursor_configured=false
for _attempt in {1..500}; do
    if XCURSOR_PATH=@cursorPath@ \
       XCURSOR_THEME="$cursor_theme" \
       XCURSOR_SIZE="$cursor_size" \
       @xsetroot@ -display :42 -cursor_name left_ptr 2>/dev/null; then
        cursor_configured=true
        break
    fi
    if ! kill -0 "$inner_proxy_pid" 2>/dev/null; then
        wait "$inner_proxy_pid"
        exit $?
    fi
    @coreutils@/bin/sleep 0.01
done

if [[ "$cursor_configured" != true ]]; then
    printf 'Yandex Browser: could not apply the session Xcursor theme\n' >&2
fi

set +e
(
    exec -a "$browser_dir/yandex-browser" \
        "$browser_dir/yandex-browser" "${browser_args[@]}" "$@"
) &
browser_pid=$!
wait "$browser_pid"
browser_status=$?
set -e

exit "$browser_status"
