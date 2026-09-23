{ config, lib, username, ... }:

let
  cfg = config.modules.home.dconf;
in
{
  options = {
    modules = {
      home = {
        dconf = {
          enable = lib.mkEnableOption "dconf desktop settings";
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    home-manager = {
      users = {
        ${username} = {
          dconf = {
            enable = true;
            settings = {
              "org/gnome/desktop/interface" = {
                color-scheme = "prefer-dark";
                gtk-theme = "Adwaita-dark";
                icon-theme = "Papirus-Dark";
                cursor-theme = "Bibata-Modern-Classic";
                cursor-size = 24;
                font-name = "Inter 11";
                monospace-font-name = "JetBrains Mono 11";
                document-font-name = "Inter 11";
                font-antialiasing = "rgba";
                font-hinting = "slight";
              };

              "org/gnome/desktop/wm/preferences" = {
                button-layout = ":";
              };

              "org/gtk/settings/file-chooser" = {
                sort-directories-first = true;
              };
            };
          };
        };
      };
    };
  };
}
