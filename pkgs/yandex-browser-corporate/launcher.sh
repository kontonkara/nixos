#!@bash@/bin/bash
# Runs inside the sandbox (as PID 2 of its PID namespace; the sandbox ends
# when this script does). Forwards to a running instance, or prepares the
# profile and runs Chromium.
set -euo pipefail

browser_dir=@browser@
license_seed=@licenseSeed@
# xdg-open/gio shims first: Chromium hands URLs and files to them.
export PATH=@path@

profile_dir=@userDataDir@

# /tmp is shared by every launch. Whoever holds this lock owns the profile;
# the fd is inherited by the browser and held for its whole lifetime.
exec {guard_fd}>/tmp/.yandex-browser-corporate.lock
tries=0
until flock -n "$guard_fd"; do
    # Another launch owns the profile: hand it our arguments. Never exec
    # Chromium here, its stale-lock check can't work across sandboxes (see
    # singleton-client.c) and would open the profile a second time.
    status=0
    @singletonClient@ "$profile_dir/SingletonSocket" "$browser_dir/yandex_browser" "$@" || status=$?
    case $status in
        0) exit 0 ;;
        2)
            # Still starting up (or shutting down): retry for up to 30 s.
            if (( ++tries >= 150 )); then
                echo "yandex-browser-corporate: the running instance does not accept launches" >&2
                exit 1
            fi
            sleep 0.2
            ;;
        *)
            echo "yandex-browser-corporate: the running instance does not respond" >&2
            exit 1
            ;;
    esac
done

# From here on this is the only instance.

# The sops secret is only a seed: the browser renews the live copy itself.
# After rotating the secret, reseed with YANDEX_LICENSE_RESEED=1.
license_file=$HOME/.yandex/browser/license
mkdir -p "${license_file%/*}" "$profile_dir"
if [[ ${YANDEX_LICENSE_RESEED-0} == 1 || ! -s $license_file ]]; then
    if [[ -r $license_seed ]]; then
        install -m600 "$license_seed" "$license_file"
    else
        echo "yandex-browser-corporate: license seed $license_seed is not readable" >&2
    fi
fi

# Chromium takes its default download folder from user-dirs.dirs; ~/downloads
# is the host's download dir bound into the sandbox. Older profiles remember
# ~/Downloads as the "Save as" folder, so keep that name pointing at it too.
printf 'XDG_DOWNLOAD_DIR="$HOME/downloads"\n' >"$XDG_CONFIG_HOME/user-dirs.dirs"
if [[ ! -e $HOME/Downloads && ! -L $HOME/Downloads ]]; then
    ln -s downloads "$HOME/Downloads"
fi

# Extra roots (Yandex's internal PKI) go into the sandbox's own NSS database,
# which Chromium trusts for every request, including the security event
# connector that ignores policy-provided roots. The host is not touched.
# Roots we added are recorded so ones dropped from the configuration are
# removed again. A failure only costs that trust, never the start.
nssdb=$HOME/.pki/nssdb
managed_roots=$nssdb/nixpak-managed-roots
mkdir -p "$nssdb"
if [[ ! -e $nssdb/cert9.db ]]; then
    certutil -d "sql:$nssdb" -N --empty-password ||
        echo "yandex-browser-corporate: could not create $nssdb" >&2
fi
wanted_roots=()
for cert in @rootCertificates@/*; do
    [[ -e $cert ]] || continue
    name=${cert##*/}
    name=${name%.pem}
    wanted_roots+=("$name")
    certutil -d "sql:$nssdb" -A -t C,, -n "$name" -i "$cert" ||
        echo "yandex-browser-corporate: could not add root $name" >&2
done
if [[ -r $managed_roots ]]; then
    while IFS= read -r name; do
        [[ -n $name && " ${wanted_roots[*]} " != *" $name "* ]] || continue
        certutil -d "sql:$nssdb" -D -n "$name" ||
            echo "yandex-browser-corporate: could not remove root $name" >&2
    done <"$managed_roots"
fi
printf '%s\n' "${wanted_roots[@]}" >"$managed_roots"

# SingletonLock stores hostname-pid, and PIDs inside the sandbox's PID
# namespace repeat between launches, so after a crash a stale lock can look
# alive and Chromium refuses the profile. We hold the lock above, so these
# are leftovers.
rm -f "$profile_dir/SingletonLock" \
      "$profile_dir/SingletonSocket" \
      "$profile_dir/SingletonCookie"
rm -rf /tmp/.ru.yandex.desktop.browser.*

# Relaunching (after changing flags or some settings) runs CHROME_WRAPPER
# with all of the browser's switches.
export CHROME_WRAPPER=@relaunch@
export CHROME_VERSION_EXTRA=stable
export GNOME_DISABLE_CRASH_DIALOG=SET_BY_GOOGLE_CHROME

# Chromium handles SIGTERM/SIGINT/SIGHUP with a clean shutdown; this shell
# must not end before it (the sandbox, and the browser with it, would be
# killed), so it only waits. A trap, not an ignore: Chromium gets the
# default disposition back.
trap : TERM INT HUP

# The Wayland wire sanitizer only acts in the browser process, which owns
# the Wayland connection; child processes inherit it (as does a relaunched
# browser) and it passes their calls straight through.
export LD_PRELOAD=@waylandWireSanitizer@/lib/libyandex-wayland-wire-sanitizer.so
"$browser_dir/yandex_browser" @flags@ "$@" &
browser=$!
status=0
while kill -0 "$browser" 2>/dev/null; do
    wait "$browser" && status=0 || status=$?
done

# A relaunched browser is started by the old one and outlives it: keep the
# sandbox up while a browser process (or its relauncher) is left. Chromium
# rewrites its process title, so its cmdline may be one space-joined string.
# A child the old browser forked that never reached exec has the same
# command line but a single thread; a relaunched browser gains threads right
# away, so single-threaded ones only count during a short grace period.
browser_alive() {
    local grace=$1 proc args cmdline key value threads
    for proc in /proc/[0-9]*; do
        [[ ${proc#/proc/} == "$$" ]] && continue
        { mapfile -d '' -t args <"$proc/cmdline"; } 2>/dev/null || continue
        cmdline=" ${args[*]} "
        [[ $cmdline == *"/yandex_browser "* ]] || continue
        [[ $cmdline == *" --type="* && $cmdline != *" --type=relauncher "* ]] && continue
        threads=1
        {
            while read -r key value _; do
                if [[ $key == Threads: ]]; then
                    threads=$value
                    break
                fi
            done <"$proc/status"
        } 2>/dev/null || continue
        (( threads > 1 || grace > 0 )) && return 0
    done
    return 1
}
grace=5
while browser_alive "$grace"; do
    sleep 1
    (( grace > 0 )) && grace=$((grace - 1))
done

exit "$status"
