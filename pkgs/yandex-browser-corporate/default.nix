{ config, lib, pkgs, inputs, ... }:

let
  cfg = config.programs.yandex-browser-corporate;
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
        Policies merged over the vendor-managed policy set.  Portal-backed
        save dialogs remain mandatory and cannot be disabled here.
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
            extraCommandLineArgs
            extraManagedPolicies
            extraRecommendedPolicies
            timezone
            ;
          cursorPackages = cfg.cursor.packages;
          gpuPackage = config.hardware.graphics.package;
        };
      })
    ];

    environment.systemPackages = [ pkgs.yandex-browser-corporate ];

    xdg.mime.defaultApplications = lib.mkIf cfg.makeDefaultBrowser {
      "text/html" = "ru.yandex.Browser.Corporate.desktop";
      "application/xhtml+xml" = "ru.yandex.Browser.Corporate.desktop";
      "x-scheme-handler/http" = "ru.yandex.Browser.Corporate.desktop";
      "x-scheme-handler/https" = "ru.yandex.Browser.Corporate.desktop";
    };

    xdg.icons.enable = lib.mkDefault true;
    xdg.mime.enable = lib.mkDefault true;
  };
}
