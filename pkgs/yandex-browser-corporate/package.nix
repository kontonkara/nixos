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
        find_ffmpeg|update_codecs)
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

  managedPoliciesFile = runCommand "yandex-browser-managed-policies.json" {
    nativeBuildInputs = [ jq ];
    extraPoliciesJson = builtins.toJSON extraManagedPolicies;
    passAsFile = [ "extraPoliciesJson" ];
  } ''
    # Downloads must pass through the desktop FileChooser/Document portal.
    # Disabling background mode also prevents a non-functional tray action
    # from trying to invoke this non-Flatpak application through flatpak(1).
    jq --sort-keys -s \
      '.[0] * .[1] * {
        "BackgroundModeEnabled": false,
        "PromptForDownloadLocation": true
      }' \
      ${customisation}/${customisation.managedPoliciesSubpath} \
      "$extraPoliciesJsonPath" > "$out"
  '';

  recommendedPoliciesFile = writeText "yandex-browser-recommended-policies.json"
    (builtins.toJSON extraRecommendedPolicies);

  systemIntegration = runCommand "yandex-browser-corporate-integration" { } ''
    vendor_share=${vendor}/share
    mkdir -p "$out/share"

    install -Dm644 "$vendor_share/applications/yandex-browser.desktop" \
      "$out/share/applications/${desktopFile}"
    substituteInPlace "$out/share/applications/${desktopFile}" \
      --replace-fail "/usr/bin/yandex-browser-corporate" "yandex-browser-corporate" \
      --replace-fail "Name=Yandex Browser" "Name=Yandex Browser Corporate"
    substituteInPlace "$out/share/applications/${desktopFile}" \
      --replace-fail "StartupNotify=true" \
        "StartupNotify=true
StartupWMClass=${appId}"

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
    };
  };

  browserEnvironment = symlinkJoin {
    name = "yandex-browser-corporate-runtime";
    paths = [
      vendorFiltered
      partnerData
      systemIntegration
    ];
    postBuild = ''
      install -Dm755 ${browserWrapper} "$out/bin/yandex-browser-corporate"
      install -Dm644 ${managedPoliciesFile} \
        "$out/etc/opt/yandex/browser/policies/managed/managed_policies.json"
      ${lib.optionalString (extraRecommendedPolicies != { }) ''
        install -Dm644 ${recommendedPoliciesFile} \
          "$out/etc/opt/yandex/browser/policies/recommended/recommended_policies.json"
      ''}
    '';
  };

  spoofedMachineId = writeText "yandex-browser-machine-id" (
    builtins.substring 0 32 (
      builtins.hashString "sha256" "yandex-browser-corporate-nixpak-machine-id"
    )
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

            PATH = lib.makeBinPath [ coreutils ];
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
