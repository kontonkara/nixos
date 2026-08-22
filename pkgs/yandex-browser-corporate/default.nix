{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

let
  cfg = config.programs.yandex-browser-corporate;
  appId = "ru.yandex.Browser.Corporate";

  # Plasma routes Quit/launch actions for apps detected as Flatpak through
  # flatpak(1).  The sandbox must keep /.flatpak-info for portals, so provide
  # the two operations our app id actually needs; everything else fails
  # exactly like a missing Flatpak installation would.
  hostFlatpakShim = pkgs.writeShellScriptBin "flatpak" ''
    set -euo pipefail
    cmd=''${1-}
    target=''${2-}
    if [[ "$cmd" == kill && "$target" == "${appId}" ]]; then
      exec ${pkgs.procps}/bin/pkill -TERM -f \
        '/opt/yandex/browser/yandex-browser'
    fi
    if [[ "$cmd" == run && "$target" == "${appId}" ]]; then
      shift 2 || true
      exec ${pkgs.yandex-browser-corporate}/bin/yandex-browser-corporate "$@"
    fi
    printf 'flatpak: application not installed\n' >&2
    exit 1
  '';
in
{
  options.programs.yandex-browser-corporate = {
    enable = lib.mkEnableOption "the corporate Yandex Browser in a nixpak sandbox";

    licenseSecretPath = lib.mkOption {
      type = lib.types.str;
      default = "/run/secrets/yandex-browser";
      description = ''
        Absolute path to the read-only seed for the corporate license.  On the
        first launch it is copied to the browser's writable private profile;
        later launches preserve the browser-rotated profile copy.
      '';
    };

    passwordStore = lib.mkOption {
      type = lib.types.enum [
        "basic"
        "gnome"
        "gnome-libsecret"
        "kwallet5"
        "kwallet6"
        "detect"
      ];
      default = "kwallet6";
      description = ''
        Chromium credential backend inside the sandbox.  kwallet6 keeps
        passwords inside the encrypted KDE wallet instead of a plaintext JSON
        file in the profile directory.
      '';
    };

    extraCommandLineArgs = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      example = [ "--force-dark-mode" ];
      description = "Additional arguments passed to every browser process.";
    };

    extraManagedPolicies = lib.mkOption {
      type = lib.types.attrs;
      default = { };
      description = ''
        Policies merged over the vendor-managed policy set.  See
        forcePortalDownloads and backgroundModeEnabled for the two
        derivation-level guarantees.
      '';
    };

    forcePortalDownloads = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Force PromptForDownloadLocation so downloads pass through the desktop
        FileChooser/Document portal.  Disable only if the portal flow is not
        required.
      '';
    };

    backgroundModeEnabled = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Allow Chromium background mode (tray keep-alive after the last window
        closes).  Leave off unless the tray Quit path has been verified.
      '';
    };

    installFlatpakShim = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Install a host-side flatpak(1) shim that handles run/kill for this
        application only, making Plasma's taskbar actions work without a real
        Flatpak installation.
      '';
    };

    extraRecommendedPolicies = lib.mkOption {
      type = lib.types.attrs;
      default = { };
      description = "Additional user-overridable browser policies.";
    };

    makeDefaultBrowser = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Use Yandex Browser Corporate for HTML and HTTP(S).";
    };

    timezone = lib.mkOption {
      type = lib.types.str;
      default = config.time.timeZone or "UTC";
      defaultText = lib.literalExpression ''config.time.timeZone or "UTC"'';
      description = "Bundled timezone visible inside the sandbox.";
    };

    cursor = {
      packages = lib.mkOption {
        type = lib.types.listOf lib.types.package;
        default = [ pkgs.kdePackages.breeze ];
        defaultText = lib.literalExpression "[ pkgs.kdePackages.breeze ]";
        description = ''
          Cursor packages available in the sandbox.  The active theme and size
          are inherited from the desktop session at runtime through its
          environment or the Settings portal, rather than configured here.
        '';
      };
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.licenseSecretPath != "" && lib.hasPrefix "/" cfg.licenseSecretPath;
        message = "programs.yandex-browser-corporate.licenseSecretPath must be an absolute path.";
      }
      {
        assertion = !(cfg.installFlatpakShim && config.services.flatpak.enable);
        message = ''
          programs.yandex-browser-corporate.installFlatpakShim conflicts with
          services.flatpak.enable: both would place a `flatpak` executable on
          the system PATH.
        '';
      }
    ];

    nixpkgs.overlays = [
      (final: _prev: {
        yandex-browser-corporate-unwrapped =
          final.callPackage ./yandex-browser-corporate.nix { };
        yandex-browser-customisation =
          final.callPackage ./yandex-browser-customisation.nix { };
        yandex-browser-corporate = final.callPackage ./package.nix {
          inherit inputs;
          inherit (cfg)
            licenseSecretPath
            passwordStore
            extraCommandLineArgs
            extraManagedPolicies
            forcePortalDownloads
            backgroundModeEnabled
            extraRecommendedPolicies
            timezone
            ;
          cursorPackages = cfg.cursor.packages;
          gpuPackage = config.hardware.graphics.package;
          enablePrinting = config.services.printing.enable;
          machineIdSeed = "yandex-browser-corporate:${config.networking.hostName}";
        };
      })
    ];

    environment.systemPackages =
      [ pkgs.yandex-browser-corporate ]
      ++ lib.optional cfg.installFlatpakShim hostFlatpakShim;

    xdg.mime.defaultApplications = lib.mkIf cfg.makeDefaultBrowser {
      "text/html" = "${appId}.desktop";
      "application/xhtml+xml" = "${appId}.desktop";
      "x-scheme-handler/http" = "${appId}.desktop";
      "x-scheme-handler/https" = "${appId}.desktop";
    };

    xdg.icons.enable = lib.mkDefault true;
    xdg.mime.enable = lib.mkDefault true;
  };
}
