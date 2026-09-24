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
            # No prefer-dark here: libadwaita warns it's unsupported and takes
            # the dark scheme from colorScheme (dconf/portal) anyway.
            gtk4.extraConfig = {
              gtk-decoration-layout = ":";
            };
          };
        };
      };
    };
  };
}
