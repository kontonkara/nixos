#!@bash@/bin/bash
# Seeds the rotating corporate license, then execs Chromium.
set -euo pipefail

browser_dir=@browser@
license_seed=@licenseSeed@
export PATH=@coreutils@/bin:@utilLinux@/bin:@xz@/bin:$PATH

# Yandex's custom titlebar emits xdg_surface.set_window_geometry with 0x0,
# which KWin rejects and takes the process down (e.g. on right-click).
# Sanitize the Wayland wire stream instead of patching libwayland-client.
export LD_PRELOAD="@waylandWireSanitizer@/lib/libyandex-wayland-wire-sanitizer.so${LD_PRELOAD:+:$LD_PRELOAD}"

# HOME is the synthetic sandbox home. Live license copy is owned by the
# browser and rotated via license-renewal; the sops secret is only a seed.
license_file=${YANDEX_LICENSE_FILE:-$HOME/.yandex/browser/license}
profile_dir=${XDG_CONFIG_HOME:-$HOME/.config}/yandex-browser

mkdir -p "$(dirname "$license_file")" "$profile_dir"
if [[ ${YANDEX_LICENSE_RESEED-0} == 1 ]]; then
    install -Dm600 "$license_seed" "$license_file"
elif [[ -r $license_seed && ! -s $license_file ]]; then
    install -Dm600 "$license_seed" "$license_file"
elif [[ ! -r $license_seed ]]; then
    echo "yandex-browser-corporate: license seed $license_seed is not readable" >&2
fi

if [[ ${YANDEX_BROWSER_WRAPPER_DEBUG-0} == 1 ]]; then
    mkdir -p "${XDG_STATE_HOME:-$HOME/.local/state}/yandex-browser-corporate"
    {
        echo "seed=$license_seed"
        echo "license_file=$license_file"
        echo "args=$*"
    } >>"${XDG_STATE_HOME:-$HOME/.local/state}/yandex-browser-corporate/wrapper.log"
fi

# Chromium's hostname-PID SingletonLock survives PID-namespace reuse after a
# hard kill. Drop it when we are the only wrapper holding this lock. The lock
# lives in the shared /tmp so concurrent starts serialise correctly.
exec {guard_fd}>/tmp/.yandex-browser-corporate.lock
if flock -n "$guard_fd"; then
    rm -f "$profile_dir/SingletonCookie" \
          "$profile_dir/SingletonLock" \
          "$profile_dir/SingletonSocket"
    # Stale Yandex desktop-browser runtime dirs from a previous primary.
    rm -rf /tmp/.ru.yandex.desktop.browser.* 2>/dev/null || true
    # Unclean shutdown leftovers. We hold the only wrapper lock, so no
    # other instance is using these databases. Without this Chromium
    # reports "Your profile opened incorrectly" (UKM/LevelDB/Passman).
    find "$profile_dir" \( -name '*-journal' -o -name '*-wal' -o -name '*-shm' \) \
        -type f -delete 2>/dev/null || true
    find "$profile_dir" -name LOCK -type f -delete 2>/dev/null || true
fi

export CHROME_WRAPPER=$0
export CHROME_VERSION_EXTRA=stable
export GNOME_DISABLE_CRASH_DIALOG=SET_BY_GOOGLE_CHROME

exec -a "$browser_dir/yandex_browser" "$browser_dir/yandex_browser" \
    --ozone-platform=wayland \
    --enable-wayland-ime \
    --qt-version=6 \
    --password-store=@passwordStore@ \
    --class=@appId@ \
    --ignore-gpu-blocklist \
    --enable-features=AcceleratedVideoEncoder,VaapiIgnoreDriverChecks \
    @extraArgs@ \
    "$@"
