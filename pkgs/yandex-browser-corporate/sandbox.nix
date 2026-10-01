{
  mkNixPak,
  lib,
  pkgs,
  unwrapped,
  customisation,
  appId,
  licenseSeedPath,
  keyStorage,
  migrateFromKeyring,
  extraArgs,
  extraManagedPolicies,
  extraRootCertificates,
  graphicsDriver,
  renderNode,
  fontconfigEtc,
  extraFonts,
  iconThemes,
  cursorThemes,
  persistentHome,
  homeBinds,
  downloadDir,
  runtimeSubdir,
  userDataDir,
  isolateNetwork,
  timeZone,
  debugPort,
}:

let
  sandboxHome = "/home/yandex-browser";
  profileDir =
    if userDataDir == null then "${sandboxHome}/.config/yandex-browser" else userDataDir;

  # Chromium's OS-level key storage (cookies, passwords, card data):
  #   portal  - a per-app secret from org.freedesktop.portal.Secret; the
  #             sandbox never sees the user's keyring. Chromium only asks the
  #             portal when a keyring store is selected, so it runs as
  #             gnome-libsecret with the Secret Service itself filtered out.
  #   keyring - the Secret Service itself (whole login keyring reachable).
  #   basic   - Chromium's built-in fixed key; relies on disk encryption.
  passwordStore =
    {
      portal = "gnome-libsecret";
      keyring = "gnome-libsecret";
      basic = "basic";
    }
    .${keyStorage};

  features = [
    # VA-API decode/encode on the Mesa iGPU, zero-copy into the compositor.
    "AcceleratedVideoDecodeLinuxGL"
    "AcceleratedVideoDecodeLinuxZeroCopyGL"
    "AcceleratedVideoEncoder"
    # Camera through the xdg Camera portal instead of raw /dev/video*.
    "WebRtcPipeWireCamera"
    # Two-finger swipe for back/forward.
    "TouchpadOverscrollHistoryNavigation"
  ]
  ++ lib.optional (keyStorage == "portal") "SecretPortalKeyProviderUseForEncryption";

  flags = [
    "--ozone-platform=wayland"
    "--enable-wayland-ime"
    "--wayland-text-input-version=3"
    "--password-store=${passwordStore}"
    "--enable-features=${lib.concatStringsSep "," features}"
  ]
  ++ lib.optional (userDataDir != null) "--user-data-dir=${profileDir}"
  ++ lib.optional (debugPort != null) "--remote-debugging-port=${toString debugPort}"
  ++ extraArgs;

  # One directory, files named after their certutil nickname.
  rootCertificates = pkgs.runCommandLocal "yandex-browser-root-certificates" { } ''
    mkdir $out
    ${lib.concatMapStrings (file: ''
      cp ${file} $out/${baseNameOf file}
    '') extraRootCertificates}
  '';

  managedPolicies = pkgs.writeText "managed_policies.json" (
    builtins.toJSON (
      {
        # Tray keep-alive is more trouble than worth in a sandbox.
        BackgroundModeEnabled = false;
        # The sandbox cannot see or change the host's default browser;
        # that is set declaratively (makeDefaultBrowser) instead.
        DefaultBrowserSettingEnabled = false;
      }

      // (builtins.fromJSON (builtins.readFile "${customisation}/managed/managed_policies.json"))
      // extraManagedPolicies
    )
  );

  waylandWireSanitizer = pkgs.stdenv.mkDerivation {
    pname = "yandex-browser-wayland-wire-sanitizer";
    version = "2";
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

  browserDir = "${unwrapped}/opt/yandex/browser";

  singletonClient = pkgs.stdenv.mkDerivation {
    pname = "yandex-browser-singleton-client";
    version = "1";
    src = ./singleton-client.c;
    dontUnpack = true;
    buildPhase = ''
      runHook preBuild
      $CC -std=c11 -O2 -Wall -Wextra -Werror "$src" -o singleton-client
      runHook postBuild
    '';
    installPhase = ''
      runHook preInstall
      install -Dm755 singleton-client "$out/bin/singleton-client"
      runHook postInstall
    '';
  };

  # CHROME_WRAPPER: what Chromium may run, with all of its switches, to
  # relaunch itself from inside the same sandbox.
  relaunch = pkgs.writeShellScript "yandex-browser-corporate-relaunch" ''
    exec ${browserDir}/yandex_browser "$@"
  '';

  # Partner data the first-run helper reads from /var/lib/yandex/browser:
  # vendor files plus the customisation deb (which wins where both exist).
  # partner_config / brand_config are signed ("//sig\n{json}") and must stay
  # byte-for-byte; clids.xml is already sanitised in unwrapped.
  partnerData = pkgs.runCommandLocal "yandex-browser-corporate-partner-data" { } ''
    target=$out/var/lib/yandex/browser
    mkdir -p "$target"

    for file in partner_config master_preferences brand_config clids.xml; do
      if [[ -f ${unwrapped}/opt/yandex/browser/$file ]]; then
        install -m644 ${unwrapped}/opt/yandex/browser/$file "$target/$file"
      fi
    done

    if [[ -f ${customisation}/customization/clids.xml ]]; then
      sed -e '/<?xml/,$!d' -e 's/^[[:space:]]*//' \
        ${customisation}/customization/clids.xml >"$target/clids.xml"
    fi

    for file in partner_config master_preferences distrib_info; do
      if [[ -f ${customisation}/customization/$file ]]; then
        install -m644 ${customisation}/customization/$file "$target/$file"
      fi
    done

    for directory in resources Extensions; do
      if [[ -d ${customisation}/customization/$directory ]]; then
        cp -a ${customisation}/customization/$directory "$target/"
      fi
    done
  '';

  browserEnv = pkgs.runCommandLocal "yandex-browser-corporate-env" { } ''
    install -Dm644 ${managedPolicies} \
      $out/etc/opt/yandex/browser/policies/managed/managed_policies.json
  '';

  # Stable anonymous machine-id (avoids leaking the host one).
  spoofedMachineId = pkgs.writeText "yandex-browser-machine-id" (
    builtins.substring 0 32 (builtins.hashString "sha256" "yandex-browser-corporate:${appId}")
    + "\n"
  );

  # org.gtk.Settings.FileChooser lives in gtk3's schemas. GSETTINGS_SCHEMA_DIR
  # must be a single compiled directory or GTK dialogs abort.
  gtkSchemas = pkgs.runCommandLocal "yandex-browser-gsettings-schemas" { } ''
    mkdir -p $out/share/glib-2.0/schemas
    for xml in \
        ${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.name}/glib-2.0/schemas/*.xml \
        ${pkgs.gtk3}/share/gsettings-schemas/${pkgs.gtk3.name}/glib-2.0/schemas/*.xml; do
      ln -s "$xml" $out/share/glib-2.0/schemas/
    done
    ${pkgs.glib.dev}/bin/glib-compile-schemas $out/share/glib-2.0/schemas
  '';

  # Inside the sandbox xdg-open must not try to run host programs: GLib
  # notices /.flatpak-info and routes URIs and files through the OpenURI
  # portal, which opens them with the host's default handler (and translates
  # sandbox paths via the passed file descriptor).
  portalShims = pkgs.writeShellScriptBin "xdg-open" ''
    exec ${pkgs.glib.bin}/bin/gio open "$@"
  '';

  # The launcher (running inside the sandbox) is the nixpak app.
  launcher = pkgs.runCommandLocal "yandex-browser-corporate-launcher" { } ''
    mkdir -p $out/bin
    substitute ${./launcher.sh} $out/bin/yandex-browser-corporate \
      --replace-fail @bash@ ${pkgs.bash} \
      --replace-fail @browser@ ${browserDir} \
      --replace-fail @licenseSeed@ ${lib.escapeShellArg (lib.escapeShellArg licenseSeedPath)} \
      --replace-fail @path@ ${
        lib.makeBinPath [
          portalShims
          pkgs.coreutils
          pkgs.util-linux
          pkgs.xz
          pkgs.nss.tools
        ]
      } \
      --replace-fail @waylandWireSanitizer@ ${waylandWireSanitizer} \
      --replace-fail @rootCertificates@ ${rootCertificates} \
      --replace-fail @userDataDir@ ${lib.escapeShellArg (lib.escapeShellArg profileDir)} \
      --replace-fail @singletonClient@ ${singletonClient}/bin/singleton-client \
      --replace-fail @relaunch@ ${relaunch} \
      --replace-fail @flags@ ${lib.escapeShellArg (lib.escapeShellArgs flags)}
    chmod +x $out/bin/yandex-browser-corporate
  '';

  # Fonts: mirror the host's fontconfig (same families, aliases, hinting)
  # and add the user's own font packages on top.
  hostFonts = fontconfigEtc != null;
  fontconfigEtcRef = pkgs.runCommandLocal "yandex-browser-fontconfig-etc" { } ''
    ln -s ${fontconfigEtc} $out
  '';
  fontsConf = pkgs.writeText "yandex-browser-fonts.conf" ''
    <?xml version="1.0"?>
    <!DOCTYPE fontconfig SYSTEM "urn:fontconfig:fonts.dtd">
    <fontconfig>
      <include ignore_missing="no">/etc/fonts/fonts.conf</include>
      ${lib.concatMapStringsSep "\n  " (font: "<dir>${font}/share/fonts</dir>") extraFonts}
    </fontconfig>
  '';

  dataDirs = [
    pkgs.hicolor-icon-theme
    pkgs.adwaita-icon-theme
    pkgs.shared-mime-info
    pkgs.gsettings-desktop-schemas
    pkgs.gtk3
  ]
  ++ iconThemes
  ++ cursorThemes;
  cursorDirs = cursorThemes ++ [ pkgs.adwaita-icon-theme ];
in
mkNixPak {
  config =
    { config, sloth, ... }:
    let
      runtimePath = suffix: sloth.concat' sloth.runtimeDir suffix;
      home = suffix: "${sandboxHome}${suffix}";
      # Host paths are given as "$HOME/..." so they work for any user.
      hostPath =
        path:
        if lib.hasPrefix "$HOME/" path then
          sloth.concat' sloth.homeDir (lib.removePrefix "$HOME" path)
        else
          path;
    in
    {
      app.package = launcher;
      app.binPath = "bin/yandex-browser-corporate";

      flatpak.appId = appId;

      # Session bus through xdg-dbus-proxy. Portals cover files, URIs,
      # screencast, camera, notifications, settings and the secret key; no
      # direct keyring, dconf, file manager or accessibility bus access.
      dbus.enable = true;
      dbus.policies = {
        "org.freedesktop.DBus" = "talk";
        "org.freedesktop.portal.*" = "talk";
        "org.freedesktop.Notifications" = "talk";
        "org.mpris.MediaPlayer2.chromium.*" = "own";
        "${appId}" = "own";
        "${appId}.*" = "own";
      }
      // lib.optionalAttrs (keyStorage == "keyring" || migrateFromKeyring) {
        "org.freedesktop.secrets" = "talk";
      };

      # GPU devices are bound by hand below (only the chosen render node).
      gpu.enable = false;

      fonts = lib.mkIf (!hostFonts) {
        enable = true;
        fonts = [
          pkgs.dejavu_fonts
          pkgs.liberation_ttf
          pkgs.noto-fonts
          pkgs.noto-fonts-color-emoji
        ]
        ++ extraFonts;
      };

      etc.sslCertificates.enable = true;
      locale.enable = true;
      # A named zone (plus TZ) lets ICU report "Europe/Minsk" to web pages
      # instead of a bare offset read from a copied /etc/localtime.
      timeZone =
        if timeZone == null then
          {
            enable = true;
            provider = "host";
          }
        else
          {
            enable = true;
            provider = "bundle";
            zone = timeZone;
          };

      # Own network namespace: the internet and LAN work through pasta, but
      # services bound to the host's loopback (proxies' control APIs, dev
      # servers, CUPS, ...) are unreachable.
      pasta = lib.mkIf isolateNetwork {
        enable = true;
        mode = "isolate";
        args = lib.mkIf (debugPort != null) (
          lib.mkForce [
            "--config-net"
            "--no-dhcp"
            "--no-dhcpv6"
            "--no-ra"
            "--no-map-gw"
            "--tcp-ns"
            "none"
            "--udp-ns"
            "none"
            # Debug builds only: expose DevTools on the host's loopback.
            "--tcp-ports"
            "127.0.0.1/${toString debugPort}"
            "--host-lo-to-ns-lo"
            "--udp-ports"
            "none"
            "--ns-ifname"
            "eth0"
            "--address"
            "192.168.1.100"
            "--netmask"
            "255.255.255.0"
            "--gateway"
            "192.168.1.1"
            "--mac-addr"
            "52:54:00:12:34:56"
            "--dns-forward"
            "192.168.1.1"
            "--search"
            "none"
          ]
        );
      };

      bubblewrap = {
        network = true;
        # IPC namespace is not shared: Chromium only needs Wayland/PipeWire.
        shareIpc = false;
        dieWithParent = true;
        clearEnv = true;
        # Only the closure of the browser, drivers and themes is visible.
        bindEntireStore = false;
        extraStorePaths = [
          graphicsDriver
          gtkSchemas
          config.locale.package
        ]
        ++ dataDirs
        ++ lib.optionals hostFonts [
          fontconfigEtcRef
          fontsConf
        ]
        ++ lib.optional (timeZone != null) pkgs.tzdata
        ++ extraFonts;

        apivfs = {
          proc = true;
          dev = true;
        };

        # Wayland comes from the wl-security-context listener (restricted
        # client: no screencopy, data-control, layer-shell, virtual input).
        sockets = {
          wayland = true;
          pipewire = true;
          pulse = true;
          x11 = false;
        };

        bind.rw = [
          # Shared by every launch: Chromium's SingletonSocket dir and the
          # launcher's flock must survive so a second start forwards to the
          # first instance.
          [
            (sloth.mkdir (runtimePath "/app/${runtimeSubdir}/tmp"))
            "/tmp"
          ]
          # Persistent synthetic HOME (like ~/.var/app/<id>): profile, Mesa
          # shader cache, fontconfig cache, NSS certificate DB. The real home
          # is neither visible nor named.
          [
            (sloth.mkdir (hostPath persistentHome))
            sandboxHome
          ]
        ]
        # Pre-existing profile locations stay where they are on the host.
        ++ lib.mapAttrsToList (inner: outer: [
          (hostPath outer)
          (home "/${inner}")
        ]) homeBinds
        ++ [
          [
            (sloth.mkdir (hostPath downloadDir))
            (home "/downloads")
          ]
          # Only documents granted to this app, as Flatpak does.
          [
            (runtimePath "/doc/by-app/${appId}")
            (runtimePath "/doc")
          ]
        ];

        bind.ro = [
          licenseSeedPath
          [
            "${partnerData}/var/lib/yandex/browser"
            "/var/lib/yandex/browser"
          ]
          [
            "${browserEnv}/etc/opt/yandex/browser"
            "/etc/opt/yandex/browser"
          ]
          [
            "${spoofedMachineId}"
            "/etc/machine-id"
          ]
          [
            "${graphicsDriver}"
            "/run/opengl-driver"
          ]
          # libdrm/Mesa identify the GPU through sysfs. Only the GPUs' own
          # device directories (found by the entrypoint): the rest of the PCI
          # tree carries NIC MAC addresses and disk/USB serial numbers.
          "/sys/dev/char"
        ]
        ++ map (
          slot: sloth.envOr "YANDEX_BROWSER_GPU_SYSFS_${toString slot}" "/nonexistent"
        ) (lib.range 0 3)
        ++ lib.optionals hostFonts [
          [
            "${fontconfigEtc}"
            "/etc/fonts"
          ]
        ];

        bind.dev =
          if renderNode == null then
            [ "/dev/dri" ]
          else
            [
              [
                renderNode
                "/dev/dri/renderD128"
              ]
            ];

        env = {
          HOME = sandboxHome;
          USER = "yandex-browser";
          LOGNAME = "yandex-browser";
          LANG = sloth.envOr "LANG" "en_US.UTF-8";
          XDG_CONFIG_HOME = home "/.config";
          XDG_CACHE_HOME = home "/.cache";
          XDG_DATA_HOME = home "/.local/share";
          XDG_STATE_HOME = home "/.local/state";
          XDG_RUNTIME_DIR = sloth.runtimeDir;
          XDG_SESSION_TYPE = "wayland";
          XDG_CURRENT_DESKTOP = sloth.envOr "XDG_CURRENT_DESKTOP" "";
          WAYLAND_DISPLAY = sloth.env "WAYLAND_DISPLAY";
          PULSE_SERVER = sloth.concat [
            "unix:"
            sloth.runtimeDir
            "/pulse/native"
          ];
          GDK_BACKEND = "wayland";
          GTK_USE_PORTAL = "1";
          NO_AT_BRIDGE = "1";
          XDG_DATA_DIRS = lib.makeSearchPath "share" dataDirs;
          GSETTINGS_SCHEMA_DIR = "${gtkSchemas}/share/glib-2.0/schemas";
          XCURSOR_PATH = lib.concatMapStringsSep ":" (p: "${p}/share/icons") cursorDirs;
          XCURSOR_THEME = sloth.envOr "XCURSOR_THEME" "Adwaita";
          XCURSOR_SIZE = sloth.envOr "XCURSOR_SIZE" "24";
          # Mesa only: the dGPU's userspace driver is never loaded, so
          # the browser cannot wake it up.
          LIBVA_DRIVERS_PATH = "/run/opengl-driver/lib/dri";
          __EGL_VENDOR_LIBRARY_DIRS = "/run/opengl-driver/share/glvnd/egl_vendor.d";
          YANDEX_LICENSE_RESEED = sloth.envOr "YANDEX_LICENSE_RESEED" "0";
        }
        // lib.optionalAttrs (timeZone != null) {
          TZ = timeZone;
          TZDIR = "${pkgs.tzdata}/share/zoneinfo";
        }
        // lib.optionalAttrs hostFonts {
          FONTCONFIG_FILE = "${fontsConf}";
        };
      };
    };
}
