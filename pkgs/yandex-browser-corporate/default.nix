{
  pkgs,
  nixpak,
  lib ? pkgs.lib,

  appId ? "ru.yandex.Browser.Corporate",
  licenseSeedPath ? "/run/secrets/yandex-browser",
  # "portal" | "keyring" | "basic", see sandbox.nix.
  keyStorage ? "portal",
  # Portal mode, but still let Chromium read data encrypted with the old
  # keyring key (v11) so it can be re-encrypted. Temporary.
  migrateFromKeyring ? false,
  extraArgs ? [ ],
  extraManagedPolicies ? { },
  # Roots trusted inside the browser only. Yandex's internal hosts
  # (ext-bro.sec.yandex.net, *.oscar.yandex.net, ...) chain to
  # YandexInternalRootCA, which corporate machines have system-wide:
  # https://crls.yandex.net/YandexInternalRootCA.crt
  extraRootCertificates ? [ ./YandexInternalRootCA.pem ],

  # Mounted as the sandbox's /run/opengl-driver (Mesa only).
  graphicsDriver ? pkgs.mesa,
  # Render node given to the browser, e.g.
  # "/dev/dri/by-path/pci-0000:06:00.0-render"; null exposes all of /dev/dri.
  renderNode ? null,
  # The host's /etc/fonts (config.environment.etc.fonts.source); null uses a
  # small built-in font set.
  fontconfigEtc ? null,
  extraFonts ? [ ],
  iconThemes ? [ ],
  cursorThemes ? [ ],

  # Host directories, "$HOME/..." is resolved at launch.
  persistentHome ? "$HOME/.local/share/yandex-browser-corporate",
  # Sandbox-home-relative path -> host path, bound over persistentHome.
  homeBinds ? {
    ".config/yandex-browser" = "$HOME/.config/yandex-browser";
    ".cache/yandex-browser" = "$HOME/.cache/yandex-browser";
    ".yandex/browser" = "$HOME/.yandex/browser";
  },
  downloadDir ? "$HOME/downloads",
  runtimeSubdir ? appId,
  # Profile directory inside the sandbox; null is the browser's default.
  userDataDir ? null,

  isolateNetwork ? true,
  # Olson name (config.time.timeZone); null copies the host's /etc/localtime.
  timeZone ? null,
  waylandSecurityContext ? true,
  debugPort ? null,
}:

assert lib.elem keyStorage [
  "portal"
  "keyring"
  "basic"
];

let
  unwrapped = pkgs.callPackage ./unwrapped.nix { };
  customisation = pkgs.callPackage ./customisation.nix { };
  wlSecurityContext = pkgs.callPackage ./wl-security-context { };

  mkNixPak = nixpak.lib.nixpak {
    inherit pkgs;
    inherit (pkgs) lib;
  };

  sandboxed = import ./sandbox.nix {
    inherit
      mkNixPak
      lib
      pkgs
      unwrapped
      customisation
      appId
      licenseSeedPath
      keyStorage
      migrateFromKeyring
      extraArgs
      extraManagedPolicies
      extraRootCertificates
      graphicsDriver
      renderNode
      fontconfigEtc
      extraFonts
      iconThemes
      cursorThemes
      persistentHome
      homeBinds
      downloadDir
      runtimeSubdir
      userDataDir
      isolateNetwork
      timeZone
      debugPort
      ;
  };

  sandboxScript = "${sandboxed.config.script}/bin/yandex-browser-corporate";

  # Runs outside the sandbox, before nixpak's launcher.
  entrypoint = pkgs.writeShellScript "yandex-browser-corporate" ''
    PATH=${lib.makeBinPath [ pkgs.coreutils ]}


    # The sandbox only sees the sysfs directories of the GPUs it may use;
    # libdrm and Mesa identify the device there.
    slot=0
    for node in ${
      if renderNode == null then "/dev/dri/renderD*" else lib.escapeShellArg renderNode
    }; do
      if (( slot < 4 )) &&
          real=$(realpath -e "$node" 2>/dev/null) &&
          device=$(realpath -e "/sys/class/drm/''${real##*/}/device" 2>/dev/null); then
        export YANDEX_BROWSER_GPU_SYSFS_$slot=$device
        slot=$((slot + 1))
      else
        echo "yandex-browser-corporate: GPU $node not available, rendering in software" >&2
      fi
    done

    # Start the document portal if it isn't running yet: its FUSE mount must
    # exist when bwrap binds the app's view of it, or files picked in the
    # file chooser are missing inside the sandbox for the whole session.
    ${pkgs.glib.bin}/bin/gdbus call --session \
      --dest org.freedesktop.portal.Documents \
      --object-path /org/freedesktop/portal/documents \
      --method org.freedesktop.portal.Documents.GetMountPoint >/dev/null 2>&1 || true

    ${
      if waylandSecurityContext then
        ''
          # A restricted Wayland socket from the compositor's security-context
          # protocol instead of the session socket.
          exec ${lib.getExe wlSecurityContext} \
            --app-id ${lib.escapeShellArg appId} \
            --instance-id "$$" \
            --socket "wayland-${appId}-$$" \
            -- ${sandboxScript} "$@"
        ''
      else
        ''
          exec ${sandboxScript} "$@"
        ''
    }
  '';
in
pkgs.runCommandLocal "yandex-browser-corporate-${unwrapped.version}"
  {
    passthru = {
      inherit
        unwrapped
        customisation
        sandboxed
        appId
        ;
    };
    meta = unwrapped.meta // {
      description = "Yandex Browser Corporate in a nixpak sandbox";
      mainProgram = "yandex-browser-corporate";
    };
  }
  ''
    install -Dm755 ${entrypoint} $out/bin/yandex-browser-corporate

    # Keep the vendor actions' arguments (--incognito, new window, ...).
    # Yandex hardcodes its Wayland app_id to "yandex-browser" (no --class or
    # CHROME_DESKTOP support), so StartupWMClass has to match that.
    desktop=$out/share/applications/${appId}.desktop
    mkdir -p $out/share/applications
    sed \
      -e "s|^Exec=[^ ]*|Exec=$out/bin/yandex-browser-corporate|" \
      -e '/^TryExec=/d' \
      -e '/^NoDisplay=/d' \
      -e '/^StartupWMClass=/d' \
      -e 's|^\[Desktop Entry\]$|&\nStartupWMClass=yandex-browser|' \
      ${unwrapped}/share/applications/yandex-browser.desktop >"$desktop"

    for size in 16 24 32 48 64 128 256; do
      install -Dm644 ${unwrapped}/opt/yandex/browser/product_logo_$size.png \
        $out/share/icons/hicolor/''${size}x''${size}/apps/yandex-browser.png
    done
  ''
