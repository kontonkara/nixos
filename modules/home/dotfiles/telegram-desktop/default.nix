{ config, lib, pkgs, username, ... }:

let
  cfg = config.modules.home.telegram-desktop;
in
{
  options = {
    modules = {
      home = {
        telegram-desktop = {
          enable = lib.mkEnableOption "telegram desktop";
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
              pkgs.telegram-desktop
            ];
          };

          # Telegram keeps the applied theme in tdata, its encrypted binary
          # state, so it's picked once from this file (Settings > Chat
          # Settings > Choose from file). It re-reads the file from that path
          # at every start, so a rebuilt theme still reaches it.
          xdg = {
            dataFile = {
              "telegram-desktop/catppuccin-mocha-peach.tdesktop-theme" = {
                source = pkgs.callPackage ./catppuccin.nix { };
              };
            };
          };
        };
      };
    };
  };
}
