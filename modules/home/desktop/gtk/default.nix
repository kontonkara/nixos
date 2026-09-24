{ config, lib, username, ... }:

let
  cfg = config.modules.home.gtk;
in
{
  options = {
    modules = {
      home = {
        gtk = {
          enable = lib.mkEnableOption "gtk dark preference and decoration layout";
        };
      };
    };
  };

  # Theme, fonts, cursor and icons come from stylix (modules/home/desktop/stylix).
  config = lib.mkIf cfg.enable {
    home-manager = {
      users = {
        ${username} = {
          gtk = {
            enable = true;
            colorScheme = "dark";

            gtk3.extraConfig = {
              gtk-application-prefer-dark-theme = 1;
              gtk-decoration-layout = ":";
            };
            # colorScheme still writes prefer-dark here: libadwaita apps log
            # that it's unsupported, but GTK 4.22 picks a named theme's dark
            # variant (adw-gtk3's gtk-dark.css) only from it.
            gtk4.extraConfig = {
              gtk-decoration-layout = ":";
            };
          };
        };
      };
    };
  };
}
