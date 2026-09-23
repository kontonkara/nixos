{
  mkNixPak,
  lib,
  pkgs,
  unwrapped,
  customisation,
  licenseSeedPath,
  passwordStore,
  extraArgs,
  appId,
  extraManagedPolicies,
}:

let
  extraArgsString = lib.concatStringsSep " " (map lib.escapeShellArg extraArgs);

  managedPolicies = pkgs.writeText "managed_policies.json" (
    builtins.toJSON (
      {
        # Route downloads through the FileChooser/Document portal instead of
        # silently dropping files into ~/downloads.
        PromptForDownloadLocation = true;
        # Tray keep-alive is more trouble than worth in a sandbox.
        BackgroundModeEnabled = false;
      }
      // (builtins.fromJSON (builtins.readFile "${customisation}/managed/managed_policies.json"))
      // extraManagedPolicies
    )
  );

  # Yandex 26.4 emits 0x0 xdg_surface geometry from its custom titlebar.
  # Intercept sendmsg and rewrite those requests (see the C source).
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

  # Partner data the first-run helper reads from /var/lib/yandex/browser.
  # Vendor files plus the customisation deb, with clids.xml's leading
  # whitespace stripped so the XML declaration is first.
  partnerData = pkgs.runCommandLocal "yandex-browser-corporate-partner-data" { } ''
    target=$out/var/lib/yandex/browser
    mkdir -p "$target"

    # partner_config / brand_config are signed ("//sig\n{json}"). Never
    # rewrite them: the signature covers the body byte-for-byte.
    for file in partner_config master_preferences brand_config; do
      if [[ -f ${unwrapped}/opt/yandex/browser/$file ]]; then
        install -Dm644 ${unwrapped}/opt/yandex/browser/$file "$target/$file"
      fi
    done

    # clids.xml is plain XML with junk before the declaration.
    for source in \
        ${unwrapped}/opt/yandex/browser/clids.xml \
        ${customisation}/customization/clids.xml; do
      if [[ -f $source ]]; then
        sed -e '/<?xml/,$!d' -e 's/^[[:space:]]*//' "$source" >"$target/clids.xml"
        chmod 644 "$target/clids.xml"
      fi
    done

    if [[ -f ${customisation}/customization/distrib_info ]]; then
      install -Dm644 ${customisation}/customization/distrib_info "$target/distrib_info"
    fi

    # Corporate customisation wins for partner_config / master_preferences.
    for file in partner_config master_preferences; do
      if [[ -f ${customisation}/customization/$file ]]; then
        install -Dm644 ${customisation}/customization/$file "$target/$file"
      fi
    done

    cp -a ${customisation}/customization/resources "$target/" 2>/dev/null || true
    cp -a ${customisation}/customization/Extensions "$target/" 2>/dev/null || true
  '';

  browserEnv = pkgs.runCommandLocal "yandex-browser-corporate-env" { } ''
    mkdir -p $out/etc/opt/yandex/browser/policies/managed
    cp ${managedPolicies} \
      $out/etc/opt/yandex/browser/policies/managed/managed_policies.json
  '';

  # Stable anonymous machine-id (avoids leaking the host one).
  spoofedMachineId = pkgs.writeText "yandex-browser-machine-id" (
    builtins.substring 0 32 (builtins.hashString "sha256" "yandex-browser-corporate:${appId}")
    + "\n"
  );

  # org.gtk.Settings.FileChooser lives in gtk3, under nixpkgs'
  # share/gsettings-schemas/<name>/glib-2.0/schemas. GSETTINGS_SCHEMA_DIR
  # must be a single merged directory or the save dialog aborts.
  gtkSchemas = pkgs.runCommandLocal "yandex-browser-gsettings-schemas" { } ''
    mkdir -p $out/share/glib-2.0/schemas
    for xml in \
        ${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.name}/glib-2.0/schemas/*.xml \
        ${pkgs.gtk3}/share/gsettings-schemas/${pkgs.gtk3.name}/glib-2.0/schemas/*.xml; do
      ln -s "$xml" $out/share/glib-2.0/schemas/
    done
    ${pkgs.glib.dev}/bin/glib-compile-schemas $out/share/glib-2.0/schemas
  '';

  app = pkgs.runCommandLocal "yandex-browser-corporate-app" { } ''
    mkdir -p $out/bin $out/opt/yandex/browser
    cp -a ${unwrapped}/opt/. $out/opt/
    cp -a ${unwrapped}/share $out/
    chmod -R u+w $out/opt $out/share

    # clids.xml only — the other files in opt/yandex/browser are signed.
    if [[ -f $out/opt/yandex/browser/clids.xml ]]; then
      sed -e '/<?xml/,$!d' -e 's/^[[:space:]]*//' \
        $out/opt/yandex/browser/clids.xml \
        >$out/opt/yandex/browser/clids.xml.tmp
      mv $out/opt/yandex/browser/clids.xml.tmp $out/opt/yandex/browser/clids.xml
    fi

    rm -f $out/share/applications/*.desktop
    sed \
      -e "s|^Exec=.*|Exec=$out/bin/yandex-browser-corporate %U|" \
      -e '/^NoDisplay=/d' \
      ${unwrapped}/share/applications/yandex-browser.desktop \
      >$out/share/applications/${appId}.desktop
    echo "StartupWMClass=${appId}" >>$out/share/applications/${appId}.desktop

    for size in 16 24 32 48 64 128 256; do
      install -Dm644 $out/opt/yandex/browser/product_logo_$size.png \
        $out/share/icons/hicolor/''${size}x''${size}/apps/yandex-browser.png
    done

    substitute ${./launcher.sh} $out/bin/yandex-browser-corporate \
      --replace-fail @bash@ ${pkgs.bash} \
      --replace-fail @browser@ $out/opt/yandex/browser \
      --replace-fail @licenseSeed@ ${licenseSeedPath} \
      --replace-fail @coreutils@ ${pkgs.coreutils} \
      --replace-fail @utilLinux@ ${pkgs.util-linux} \
      --replace-fail @xz@ ${pkgs.xz} \
      --replace-fail @waylandWireSanitizer@ ${waylandWireSanitizer} \
      --replace-fail @passwordStore@ ${passwordStore} \
      --replace-fail @appId@ ${appId} \
      --replace-fail @extraArgs@ "${extraArgsString}"
    chmod +x $out/bin/yandex-browser-corporate
  '';

  sandboxHome = "/home/yandex-browser";
in
mkNixPak {
  config =
    {
      sloth,
      ...
    }:
    let
      hostAppDir = suffix: sloth.mkdir (sloth.concat' sloth.homeDir suffix);
      runtimePath = suffix: sloth.concat' sloth.runtimeDir suffix;
      runtimeAppDir = suffix: sloth.mkdir (runtimePath suffix);
    in
    {
      app.package = app;
      app.binPath = "bin/yandex-browser-corporate";

      flatpak.appId = appId;

      dbus.enable = true;
      dbus.policies = {
        "org.freedesktop.DBus" = "talk";
        "org.freedesktop.Notifications" = "talk";
        "org.freedesktop.portal.*" = "talk";
        "org.freedesktop.secrets" = "talk";
        "org.freedesktop.FileManager1" = "talk";
        "org.freedesktop.login1" = "talk";
        "ca.desrt.dconf" = "talk";
        "org.kde.kwallet5" = "talk";
        "org.kde.kwallet6" = "talk";
        "com.canonical.AppMenu.Registrar" = "talk";
        "org.kde.StatusNotifierWatcher" = "talk";
        "org.mpris.MediaPlayer2.*" = "own";
        "${appId}" = "own";
        "${appId}.*" = "own";
      };

      gpu.enable = true;
      gpu.provider = "nixos";

      fonts.enable = true;
      fonts.fonts = with pkgs; [
        dejavu_fonts
        liberation_ttf
        noto-fonts
        noto-fonts-color-emoji
      ];

      etc.sslCertificates.enable = true;
      locale.enable = true;
      timeZone = {
        enable = true;
        provider = "host";
      };

      bubblewrap = {
        network = true;
        # IPC namespace is not shared: Chromium only needs Wayland/pulse/pipewire.
        shareIpc = false;
        dieWithParent = true;
        apivfs = {
          proc = true;
          dev = true;
        };

        # Chromium loads it via dlopen on every render process.
        extraStorePaths = [ waylandWireSanitizer ];

        sockets = {
          wayland = true;
          pipewire = true;
          pulse = true;
          x11 = false;
        };

        # NOT tmpfs: Chromium's SingletonSocket and our wrapper flock must
        # survive across launches so a second start forwards to the first
        # instead of both claiming the profile ("opened incorrectly").
        bind.rw = [
          [
            (runtimeAppDir "/yandex-browser-tmp")
            "/tmp"
          ]
          # Preserve browser state, but under a synthetic HOME so the real
          # home is neither visible nor named.
          [
            (hostAppDir "/.yandex/browser")
            "${sandboxHome}/.yandex/browser"
          ]
          [
            (hostAppDir "/.config/yandex-browser")
            "${sandboxHome}/.config/yandex-browser"
          ]
          [
            (hostAppDir "/.cache/yandex-browser")
            "${sandboxHome}/.cache/yandex-browser"
          ]
          [
            (hostAppDir "/.local/share/yandex-browser")
            "${sandboxHome}/.local/share/yandex-browser"
          ]
          [
            (hostAppDir "/.local/state/yandex-browser-corporate")
            "${sandboxHome}/.local/state/yandex-browser-corporate"
          ]
          # Downloads must land under the synthetic HOME too, otherwise
          # Chromium resolves ~/downloads inside the sandbox and the write
          # goes to an invisible, non-persistent path.
          [
            (sloth.mkdir sloth.xdgDownloadDir)
            "${sandboxHome}/downloads"
          ]
          sloth.runtimeDir
          # Document portal grants land here.
          (runtimePath "/doc")
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
          [ "${spoofedMachineId}" "/etc/machine-id" ]
          # Pulse/PipeWire auth cookie; synthetic HOME would not see it otherwise.
          [
            (hostAppDir "/.config/pulse")
            "${sandboxHome}/.config/pulse"
          ]
        ];

        bind.dev = [ "/dev/dri" ];

        env = {
          HOME = sandboxHome;
          USER = sloth.envOr "USER" "browser";
          LOGNAME = sloth.envOr "LOGNAME" "browser";
          XDG_CONFIG_HOME = "${sandboxHome}/.config";
          XDG_CACHE_HOME = "${sandboxHome}/.cache";
          XDG_DATA_HOME = "${sandboxHome}/.local/share";
          XDG_STATE_HOME = "${sandboxHome}/.local/state";
          XDG_RUNTIME_DIR = sloth.runtimeDir;
          PULSE_SERVER = runtimePath "/pulse/native";
          PIPEWIRE_REMOTE = "pipewire-0";
          XDG_DOWNLOAD_DIR = "${sandboxHome}/downloads";
          XDG_SESSION_TYPE = "wayland";
          GDK_BACKEND = "wayland";
          QT_QPA_PLATFORM = "wayland";
          GTK_USE_PORTAL = "1";
          MOZ_ENABLE_WAYLAND = "1";
          NIXOS_OZONE_WL = "1";
          YANDEX_LICENSE_SECRET_PATH = licenseSeedPath;
          LIBVA_DRIVERS_PATH = "/run/opengl-driver/lib/dri";
          __EGL_VENDOR_LIBRARY_DIRS = "/run/opengl-driver/share/glvnd/egl_vendor.d";
          # Hybrid AMD iGPU + NVIDIA dGPU: point the loader at both RADV and NVK.
          VK_ICD_FILENAMES = "/run/opengl-driver/share/vulkan/icd.d/radeon_icd.x86_64.json:/run/opengl-driver/share/vulkan/icd.d/nouveau_icd.x86_64.json";
          VK_LAYER_PATH = "/run/opengl-driver/share/vulkan/explicit_layer.d";
          # gtk3 carries org.gtk.Settings.FileChooser; without it the save
          # dialog aborts the process.
          XDG_DATA_DIRS = lib.makeSearchPath "share" [
            pkgs.adwaita-icon-theme
            pkgs.hicolor-icon-theme
            pkgs.shared-mime-info
            pkgs.gsettings-desktop-schemas
            pkgs.gtk3
          ];
          GSETTINGS_SCHEMA_DIR = "${gtkSchemas}/share/glib-2.0/schemas";
        };
      };
    };
}
