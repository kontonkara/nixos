{ config, lib, pkgs, username, ... }:

let
  cfg = config.modules.home.anki;

  # Not programs.anki: HM would link prefs21.db (profiles, sync login)
  # read-only from the store. Its addons option still collects stylix's
  # ReColor add-on.
  anki = pkgs.anki.withAddons config.home-manager.users.${username}.programs.anki.addons;
in
{
  options = {
    modules = {
      home = {
        anki = {
          enable = lib.mkEnableOption "anki with stylix's recolor add-on";
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    home-manager = {
      users = {
        ${username} = {
          home = {
            packages = [
              anki
            ];
          };
        };
      };
    };
  };
}
