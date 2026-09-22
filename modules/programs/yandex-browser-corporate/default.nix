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
in
{
  options.programs.yandex-browser-corporate = {
    enable = lib.mkEnableOption "corporate Yandex Browser in a NixPak sandbox";

    licenseSecretPath = lib.mkOption {
      type = lib.types.str;
      default = "/run/secrets/yandex-browser";
      description = ''
        Read-only seed for the corporate license (sops-nix path). Seeded into
        the browser profile on first launch; the browser rotates the live
        copy afterwards. After rotating the sops secret, reseed with
        `YANDEX_LICENSE_RESEED=1 yandex-browser-corporate`.
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
      default = "gnome-libsecret";
      description = "Chromium credential backend inside the sandbox.";
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
      example = {
        BackgroundModeEnabled = false;
        PromptForDownloadLocation = true;
      };
      description = "Policies merged over the vendor-managed policy set.";
    };

    makeDefaultBrowser = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Use Yandex Browser Corporate for HTML and HTTP(S).";
    };
  };

  config = lib.mkMerge [
    # Match firefox/git/niri: importing the module turns the feature on.
    { programs.yandex-browser-corporate.enable = lib.mkDefault true; }

    (lib.mkIf cfg.enable {
      environment.systemPackages = [
        (import ../../../pkgs/yandex-browser-corporate {
          inherit pkgs;
          inherit (inputs) nixpak;
          inherit (cfg) passwordStore extraManagedPolicies;
          licenseSeedPath = cfg.licenseSecretPath;
          extraArgs = cfg.extraCommandLineArgs;
          inherit appId;
        })
      ];

      xdg.mime.defaultApplications = lib.mkIf cfg.makeDefaultBrowser {
        "text/html" = "${appId}.desktop";
        "application/xhtml+xml" = "${appId}.desktop";
        "x-scheme-handler/http" = "${appId}.desktop";
        "x-scheme-handler/https" = "${appId}.desktop";
      };

      xdg.icons.enable = lib.mkDefault true;
      xdg.mime.enable = lib.mkDefault true;
    })
  ];
}
