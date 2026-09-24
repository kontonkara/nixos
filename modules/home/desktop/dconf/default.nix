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
              # Theme, icon, cursor, font and color-scheme keys come from Home
              # Manager's gtk module and modules/home/desktop/stylix.
              "org/gnome/desktop/interface" = {
                font-antialiasing = "rgba";
                font-hinting = "slight";
              };

              "org/gnome/desktop/wm/preferences" = {
                button-layout = ":";
              };

              "org/gtk/settings/file-chooser" = {
                sort-directories-first = true;
              };
              # GTK 4 dialogs and Nautilus, which is also the GNOME portal's
              # file chooser, read this path instead.
              "org/gtk/gtk4/settings/file-chooser" = {
                sort-directories-first = true;
              };
            };
          };
        };
      };
    };
  };
}
