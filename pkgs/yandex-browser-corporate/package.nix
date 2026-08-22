{
  lib,
  pkgs,
  inputs,
  runCommand,
  replaceVarsWith,
  symlinkJoin,
  writeText,
  writeShellScript,
  jq,
  coreutils,
  bash,
  adwaita-icon-theme,
  hicolor-icon-theme,
  shared-mime-info,
  gsettings-desktop-schemas,

  cursorPackages ? [ pkgs.kdePackages.breeze ],
  gpuPackage ? pkgs.mesa,
  licenseSecretPath ? "/run/secrets/yandex-browser",
  timezone ? "UTC",
  extraCommandLineArgs ? [ ],
  extraManagedPolicies ? { },
  extraRecommendedPolicies ? { },

  # Chromium password backend.  "kwallet6" keeps credentials inside the
  # user's encrypted KDE wallet instead of a plaintext JSON profile file.
  passwordStore ? "kwallet6",
  # Bind the host CUPS socket so printing works inside the sandbox.
  enablePrinting ? false,
  # Seed for the sandbox machine-id.  Derive it from something host-unique
  # (e.g. hostname) to avoid an identical fingerprint on every machine.
  machineIdSeed ? "yandex-browser-corporate-nixpak-machine-id",
  # Managed-policy overrides kept as options so deployments can revisit them
  # without editing the derivation.
  forcePortalDownloads ? true,
  backgroundModeEnabled ? false,
}:

let
  appId = "ru.yandex.Browser.Corporate";
  desktopFile = "${appId}.desktop";
  sandboxHome = "/home/yandex-browser";

  vendor = pkgs.yandex-browser-corporate-unwrapped;
  customisation = pkgs.yandex-browser-customisation;

  findFfmpegShim = writeShellScript "yandex-browser-find-ffmpeg" ''
    browser_dir="$(${coreutils}/bin/dirname -- "$0")"
    printf '%s\n' "$browser_dir/libffmpeg.so"
  '';

  updateCodecsShim = writeShellScript "yandex-browser-update-codecs-disabled" ''
    # The package is immutable; codecs are supplied by the derivation.
    exit 0
  '';

  # The browser trusts /.flatpak-info (portals require it) and therefore
  # relaunches itself through flatpak(1) on restart/update paths.  Answer for
  # our app id only; anything else fails like a missing Flatpak would.
  flatpakShim = writeShellScript "yandex-browser-flatpak-shim" ''
    set -euo pipefail
    cmd=''${1-}
    target=''${2-}
    case "$cmd" in
      run)
        if [[ "$target" != "${appId}" ]]; then
          printf 'flatpak: application not installed: %s\n' "$target" >&2
          exit 1
        fi
        shift 2
        exec /app/bin/yandex-browser-corporate "$@"
        ;;
      *)
        printf 'flatpak: unsupported operation %q in the bundled runtime\n' \
          "$cmd" >&2
        exit 1
        ;;
    esac
  '';

  # Chromium/Yandex may use a bundled Wayland client with hidden symbols, so
  # patching the system libwayland-client does not necessarily affect Ozone.
  # This tiny interposer works below both implementations at sendmsg(2), and
  # only rewrites invalid xdg-shell dimensions before they reach KWin.
  waylandWireSanitizer = pkgs.stdenv.mkDerivation {
    pname = "yandex-browser-wayland-wire-sanitizer";
    version = "1";
    src = ./wayland-wire-sanitizer.c;
    dontUnpack = true;

    buildPhase = ''
      runHook preBuild
      $CC -std=c11 -O2 -Wall -Wextra -Werror -fPIC -shared "$src" \
        -ldl -pthread \
        -o libyandex-wayland-wire-sanitizer.so
      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall
      install -Dm755 libyandex-wayland-wire-sanitizer.so \
        "$out/lib/libyandex-wayland-wire-sanitizer.so"
      runHook postInstall
    '';
  };

  vendorFiltered = runCommand "yandex-browser-corporate-vendor" { } ''
    mkdir -p "$out/opt/yandex/browser" "$out/share"

    for entry in ${vendor}/opt/yandex/browser/*; do
      name="''${entry##*/}"
      case "$name" in
        find_ffmpeg|update_codecs|update-ffmpeg)
          ;;
        yandex-browser)
          install -Dm755 "$entry" "$out/opt/yandex/browser/$name"
          ;;
        *)
          ln -s "$entry" "$out/opt/yandex/browser/$name"
          ;;
      esac
    done

    install -Dm755 ${findFfmpegShim} "$out/opt/yandex/browser/find_ffmpeg"
    install -Dm755 ${updateCodecsShim} "$out/opt/yandex/browser/update_codecs"
    install -Dm755 ${updateCodecsShim} "$out/opt/yandex/browser/update-ffmpeg"

    # Application icons are installed by systemIntegration below.  Keeping
    # vendor/share/icons as one symlink here prevents symlinkJoin from merging
    # those icons into the final package.
    for directory in mime doc; do
      if [[ -d ${vendor}/share/$directory ]]; then
        ln -s ${vendor}/share/$directory "$out/share/$directory"
      fi
    done
  '';

  partnerData = runCommand "yandex-browser-corporate-partner-data" { } ''
    source_dir=${vendor}/opt/yandex/browser
    target_dir="$out/var/lib/yandex/browser"
    mkdir -p "$target_dir"

    for file in partner_config distrib_info master_preferences; do
      if [[ -f "$source_dir/$file" ]]; then
        install -Dm644 "$source_dir/$file" "$target_dir/$file"
      fi
    done

    if [[ -f "$source_dir/resources/configs/all_zip" ]]; then
      install -Dm644 "$source_dir/resources/configs/all_zip" \
        "$target_dir/resources/configs/all_zip"
    fi

    if [[ -d "$source_dir/Extensions" ]]; then
      mkdir -p "$target_dir/Extensions"
      find "$source_dir/Extensions" -maxdepth 1 -type f -name '*.*' \
        -exec cp -f {} "$target_dir/Extensions/" \;
    fi

    if [[ -d "$source_dir/resources" ]]; then
      mkdir -p "$target_dir/resources"
      for pattern in 'clids*.xml' 'tablo*' '*.png' '*.svg'; do
        find "$source_dir/resources" -maxdepth 1 -type f -name "$pattern" \
          -exec cp -f {} "$target_dir/resources/" \;
      done
      if [[ -d "$source_dir/resources/wallpapers" ]]; then
        mkdir -p "$target_dir/resources/wallpapers"
        find "$source_dir/resources/wallpapers" -maxdepth 1 -type f \
          -exec cp -f {} "$target_dir/resources/wallpapers/" \;
      fi
    fi

    chmod -R u+w "$target_dir"
    cp -a --no-preserve=mode,ownership \
      ${customisation}/${customisation.customizationSubpath}/. "$target_dir/"
  '';

  forcedPolicies = {
    BackgroundModeEnabled = backgroundModeEnabled;
    PromptForDownloadLocation = forcePortalDownloads;
  };

  managedPoliciesFile = runCommand "yandex-browser-managed-policies.json" {
    nativeBuildInputs = [ jq ];
    extraPoliciesJson = builtins.toJSON extraManagedPolicies;
    forcedPoliciesJson = builtins.toJSON forcedPolicies;
    passAsFile = [
      "extraPoliciesJson"
      "forcedPoliciesJson"
    ];
  } ''
    # Vendor set < deployment extras < derivation-level guarantees.
    jq --sort-keys -s '.[0] * .[1] * .[2]' \
      ${customisation}/${customisation.managedPoliciesSubpath} \
      "$extraPoliciesJsonPath" \
      "$forcedPoliciesJsonPath" > "$out"
  '';

  recommendedPoliciesFile = writeText "yandex-browser-recommended-policies.json"
    (builtins.toJSON extraRecommendedPolicies);

  systemIntegration = runCommand "yandex-browser-corporate-integration" { } ''
    vendor_share=${vendor}/share
    mkdir -p "$out/share"

    install -Dm644 "$vendor_share/applications/yandex-browser.desktop" \
      "$out/share/applications/${desktopFile}"
    # Anchor every rewrite to line starts: survives reordering, comments and
    # minor wording changes in vendor desktop entries.  Exec appears three
    # times (main entry plus two Desktop Actions); all must drop /usr/bin.
    sed -i \
      -e '/^Exec=/s|/usr/bin/yandex-browser-corporate|yandex-browser-corporate|g' \
      -e '/^Name=/s|=Yandex Browser$|=Yandex Browser Corporate|' \
      -e "/^StartupNotify=true/a StartupWMClass=${appId}" \
      "$out/share/applications/${desktopFile}"

    if [[ -f "$vendor_share/appdata/yandex-browser.appdata.xml" ]]; then
      install -Dm644 "$vendor_share/appdata/yandex-browser.appdata.xml" \
        "$out/share/appdata/yandex-browser-corporate.appdata.xml"
      substituteInPlace "$out/share/appdata/yandex-browser-corporate.appdata.xml" \
        --replace-warn "yandex-browser.desktop" "${desktopFile}" \
        --replace-warn "Yandex Browser" "Yandex Browser Corporate"
    fi

    for size in 16 24 32 48 64 128 256; do
      logo=${vendor}/opt/yandex/browser/product_logo_$size.png
      if [[ -f "$logo" ]]; then
        install -Dm644 "$logo" \
          "$out/share/icons/hicolor/''${size}x''${size}/apps/yandex-browser.png"
      fi
    done

    if [[ -f "$vendor_share/mime/packages/yandex-browser-yprotect.xml" ]]; then
      install -Dm644 "$vendor_share/mime/packages/yandex-browser-yprotect.xml" \
        "$out/share/mime/packages/yandex-browser-yprotect.xml"
    fi

    if [[ -f "$vendor_share/icons/hicolor/scalable/mimetypes/application-x-yprotect.svg" ]]; then
      install -Dm644 \
        "$vendor_share/icons/hicolor/scalable/mimetypes/application-x-yprotect.svg" \
        "$out/share/icons/hicolor/scalable/mimetypes/application-x-yprotect.svg"
    fi

    if [[ -f "$vendor_share/man/man1/yandex-browser-corporate.1.gz" ]]; then
      install -Dm644 "$vendor_share/man/man1/yandex-browser-corporate.1.gz" \
        "$out/share/man/man1/yandex-browser-corporate.1.gz"
    fi
  '';

  browserWrapper = replaceVarsWith {
    name = "yandex-browser-corporate-wrapper";
    src = ./wrapper.sh;
    isExecutable = true;
    replacements = {
      inherit appId;
      browser = "${vendorFiltered}/opt/yandex/browser";
      inherit bash coreutils;
      flock = "${pkgs.util-linux}/bin/flock";
      gdbus = "${pkgs.glib.bin}/bin/gdbus";
      waylandWireSanitizer = waylandWireSanitizer;
      cursorPath = lib.makeSearchPath "share/icons" cursorPackages;
      extraArgs = lib.escapeShellArgs extraCommandLineArgs;
      passwordStore = passwordStore;
    };
  };

  # Runs on the host before the nixpak launcher.  A missing license secret
  # otherwise surfaces as a cryptic bubblewrap "Can't find source path".
  launchPrecheck = writeShellScript "yandex-browser-corporate-precheck" ''
    set -euo pipefail
    seed=${lib.escapeShellArg licenseSecretPath}
    if [[ -n "$seed" && ! -r "$seed" ]]; then
      printf 'yandex-browser-corporate: license secret %s is not readable.\n' \
        "$seed" >&2
      printf '  restore the secret or adjust licenseSecretPath.\n' >&2
      exit 126
    fi
    self_dir=$(${coreutils}/bin/dirname \
      "$(${coreutils}/bin/readlink -f -- "$0")")
    exec "$self_dir/.yandex-browser-corporate-launcher" "$@"
  '';

  browserEnvironment = symlinkJoin {
    name = "yandex-browser-corporate-runtime";
    paths = [
      vendorFiltered
      partnerData
      systemIntegration
    ];
    postBuild = ''
      install -Dm755 ${browserWrapper} "$out/bin/yandex-browser-corporate"
      # Chromium relaunches (restart-after-update, tray flows) call flatpak(1)
      # because /.flatpak-info is present; route them back to the wrapper.
      install -Dm755 ${flatpakShim} "$out/bin/flatpak"
      install -Dm644 ${managedPoliciesFile} \
        "$out/etc/opt/yandex/browser/policies/managed/managed_policies.json"
      ${lib.optionalString (extraRecommendedPolicies != { }) ''
        install -Dm644 ${recommendedPoliciesFile} \
          "$out/etc/opt/yandex/browser/policies/recommended/recommended_policies.json"
      ''}
    '';
  };

  spoofedMachineId = writeText "yandex-browser-machine-id" (
    builtins.substring 0 32 (builtins.hashString "sha256" machineIdSeed)
    + "\n"
  );

  mkNixPak = inputs.nixpak.lib.nixpak { inherit lib pkgs; };

  sandboxed = mkNixPak {
    config = { sloth, ... }:
      let
        hostAppDir = suffix: sloth.mkdir (sloth.concat' sloth.homeDir suffix);
        runtimePath = suffix: sloth.concat' sloth.runtimeDir suffix;
        runtimeAppDir = suffix: sloth.mkdir (runtimePath suffix);
      in
      {
        flatpak = {
          inherit appId;
          inherit desktopFile;
          info.Context = {
            filesystems = "";
            sockets = "wayland;pulseaudio;";
          };
        };

        app = {
          package = browserEnvironment;
          binPath = "bin/yandex-browser-corporate";
        };

        gpu = {
          enable = true;
          provider = "bundle";
          bundlePackage = gpuPackage;
        };

        # Use the compositor's Wayland socket directly.  The browser remains
        # inside nixpak/bubblewrap; only the display socket is exposed directly
        # so Chromium can use the compositor's complete Wayland protocol set.
        waylandProxy.enable = false;

        pasta = {
          enable = true;
          mode = "isolate";
          args = [ "--quiet" ];
        };

        timeZone = {
          enable = true;
          provider = "bundle";
          zone = timezone;
        };

        locale.enable = true;
        fonts.enable = true;
        etc.sslCertificates.enable = true;

        bubblewrap = {
          network = true;
          shareIpc = false;
          bindEntireStore = false;
          extraStorePaths = [ waylandWireSanitizer ];
          clearEnv = true;
          newSession = true;
          dieWithParent = true;

          # Expose only the host Wayland display socket.  X11 remains hidden.
          sockets = {
            pulse = true;
            pipewire = true;
            wayland = true;
            x11 = false;
          };

          bind.rw = [
            # Chromium's SingletonSocket must be shared between invocations so
            # links can be forwarded to an already-running browser.  This is
            # an application-only runtime directory, not the host's /tmp.
            [
              (runtimeAppDir "/yandex-browser-tmp")
              "/tmp"
            ]

            # Preserve existing browser state, but expose it below a synthetic
            # HOME so the real home directory is neither visible nor named.
            [
              (hostAppDir "/.yandex/browser")
              "${sandboxHome}/.yandex/browser"
            ]
            [
              (hostAppDir "/.config/yandex-browser")
              "${sandboxHome}/.config/yandex-browser"
            ]
            [
              (hostAppDir "/.config/yandex-browser-corporate")
              "${sandboxHome}/.config/yandex-browser-corporate"
            ]
            [
              (hostAppDir "/.cache/yandex-browser")
              "${sandboxHome}/.cache/yandex-browser"
            ]
            [
              (hostAppDir "/.cache/yandex-browser-corporate")
              "${sandboxHome}/.cache/yandex-browser-corporate"
            ]
            [
              (hostAppDir "/.local/share/yandex-browser-corporate")
              "${sandboxHome}/.local/share"
            ]
            [
              (hostAppDir "/.local/state/yandex-browser-corporate")
              "${sandboxHome}/.local/state"
            ]

            # FileChooser grants are materialised by the Document portal here.
            (runtimePath "/doc")
          ];

          bind.ro = [
            licenseSecretPath
            [
              "${partnerData}/var/lib/yandex/browser"
              "/var/lib/yandex/browser"
            ]
            [
              "${browserEnvironment}/etc/opt/yandex/browser"
              "/etc/opt/yandex/browser"
            ]
            [ "${spoofedMachineId}" "/etc/machine-id" ]
          ] ++ lib.optionals enablePrinting [
            # Chromium talks to cupsd over its unix socket directly; without
            # this bind the print dialog silently produces nothing.
            "/run/cups"
          ];

          env = {
            HOME = sandboxHome;
            USER = sloth.envOr "USER" "browser";
            LOGNAME = sloth.envOr "LOGNAME" "browser";
            LANG = sloth.envOr "LANG" "C.UTF-8";
            XDG_RUNTIME_DIR = sloth.runtimeDir;
            XDG_CONFIG_HOME = "${sandboxHome}/.config";
            XDG_CACHE_HOME = "${sandboxHome}/.cache";
            XDG_DATA_HOME = "${sandboxHome}/.local/share";
            XDG_STATE_HOME = "${sandboxHome}/.local/state";
            XDG_SESSION_TYPE = "wayland";
            TMPDIR = "/tmp";

            # /app/bin first: the bundled flatpak shim must shadow nothing on
            # the minimal coreutils PATH, but stay reachable for Chromium
            # self-relaunch flows.
            PATH = "/app/bin:" + lib.makeBinPath [ coreutils ];

            # Standard corporate proxy variables; the vendor wrapper converts
            # them into --proxy-server/--proxy-bypass-list flags.
            http_proxy = sloth.envOr "http_proxy" "";
            https_proxy = sloth.envOr "https_proxy" "";
            all_proxy = sloth.envOr "all_proxy" "";
            no_proxy = sloth.envOr "no_proxy" "";
            XDG_DATA_DIRS = lib.makeSearchPath "share" [
              adwaita-icon-theme
              hicolor-icon-theme
              shared-mime-info
              gsettings-desktop-schemas
            ];
            GSETTINGS_SCHEMA_DIR =
              "${gsettings-desktop-schemas}/share/gsettings-schemas/${gsettings-desktop-schemas.name}/glib-2.0/schemas";

            GTK_USE_PORTAL = "1";
            GDK_BACKEND = "wayland";
            QT_QPA_PLATFORM = "wayland";
            QT_PLUGIN_PATH = lib.makeSearchPath "lib/qt-6/plugins" [
              pkgs.qt6.qtbase
              pkgs.qt6.qtwayland
            ];
            QT_QPA_PLATFORM_PLUGIN_PATH =
              lib.makeSearchPath "lib/qt-6/plugins/platforms" [
                pkgs.qt6.qtbase
                pkgs.qt6.qtwayland
              ];
            PULSE_SERVER = runtimePath "/pulse/native";
            PIPEWIRE_REMOTE = "pipewire-0";

            LIBVA_DRIVERS_PATH = "/run/opengl-driver/lib/dri";
            __EGL_VENDOR_LIBRARY_DIRS = "/run/opengl-driver/share/glvnd/egl_vendor.d";

            # Keep the selected theme and size dynamic.  The wrapper fills
            # missing values from the desktop Settings portal at each launch.
            XCURSOR_PATH = lib.makeSearchPath "share/icons" cursorPackages;
            XCURSOR_THEME = sloth.envOr "XCURSOR_THEME" "";
            XCURSOR_SIZE = sloth.envOr "XCURSOR_SIZE" "";

            SSL_CERT_FILE = "/etc/ssl/certs/ca-bundle.crt";
            YANDEX_LICENSE_SECRET_PATH = licenseSecretPath;
          };
        };

        dbus = {
          enable = true;
          policies = {
            "${appId}" = "own";
            "${appId}.*" = "own";
            "org.mpris.MediaPlayer2.chromium.*" = "own";
            "org.freedesktop.DBus" = "talk";
            "org.freedesktop.portal.*" = "talk";

            # Allow the browser to contact Plasma's tray watcher. Chromium's
            # generated org.kde.StatusNotifierItem-$PID-$ID name cannot be
            # granted narrowly: xdg-dbus-proxy only supports a trailing ".*"
            # component, not a wildcard inside a component. Do not widen this
            # to org.kde.*; background mode is disabled, so a tray item is not
            # required for browser lifetime management.
            "org.kde.StatusNotifierWatcher" = "talk";

            # System notifications through the desktop service instead of
            # native Chromium toasts, whose degenerate geometry interacts
            # badly with the wire sanitizer and KWin placement.
            "org.freedesktop.Notifications" = "talk";

            # Encrypted credential storage via the user's wallet; falls back
            # gracefully when kwalletd6 is unavailable.
            "org.kde.kwalletd6" = "talk";
            "org.kde.kwalletd5" = "talk";
            "org.freedesktop.secrets" = "talk";
          };
        };
      };
  };
in
sandboxed.config.env.overrideAttrs (old: {
  postBuild = (old.postBuild or "") + ''
    # Nixpak's .flatpak-info shim is required by portals, but advertising the
    # desktop entry as an installed Flatpak makes Plasma invoke `flatpak run`.
    desktop_file="$out/share/applications/${appId}.desktop"
    if [[ -L "$desktop_file" ]]; then
      desktop_target="$(${coreutils}/bin/readlink -f "$desktop_file")"
      ${coreutils}/bin/rm "$desktop_file"
      ${coreutils}/bin/install -Dm644 "$desktop_target" "$desktop_file"
    fi
    ${pkgs.gnused}/bin/sed -i '/^X-Flatpak=/d' "$desktop_file"

    # Put the license precheck in front of the generated bubblewrap launcher
    # so a missing secret fails with a human-readable message.
    launcher="$out/bin/yandex-browser-corporate"
    ${coreutils}/bin/mv -- "$launcher" \
      "$out/bin/.yandex-browser-corporate-launcher"
    ${coreutils}/bin/install -Dm755 ${launchPrecheck} "$launcher"
  '';

  passthru = (old.passthru or { }) // {
    inherit (vendor) version;
    inherit browserEnvironment managedPoliciesFile partnerData systemIntegration;
    unwrapped = vendor;
  };

  meta = (old.meta or { }) // {
    description = "Yandex Browser Corporate, capability-sandboxed with nixpak";
    homepage = "https://browser.yandex.ru/";
    license = lib.licenses.unfree;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    mainProgram = "yandex-browser-corporate";
    platforms = [ "x86_64-linux" ];
  };
})
