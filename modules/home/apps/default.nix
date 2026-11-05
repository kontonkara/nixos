{ config, lib, username, pkgs, ... }:

let
  cfg = config.modules.home.apps;

  # Not programs.anki: HM would link prefs21.db (profiles, sync login)
  # read-only from the store. Its addons option still collects stylix's
  # ReColor add-on.
  ankiWithAddons = pkgs.anki.withAddons config.home-manager.users.${username}.programs.anki.addons;
in
{
  options = {
    modules = {
      home = {
        apps = {
          enable = lib.mkEnableOption "home applications";
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    home-manager = {
      users = {
        ${username} = {
          home = {
            packages = with pkgs; [
              tree
              binutils
              duf
              dust
              file
              unzip
              wl-clipboard
              android-tools
              zoom-us
              ankiWithAddons
              kdePackages.kdenlive
              # AMD backend only: the NVIDIA one calls nvmlInit at start-up and
              # keeps the RTX out of D3cold while nvtop is open.
              nvtopPackages.amd
            ];
          };
        };
      };
    };
  };
}
