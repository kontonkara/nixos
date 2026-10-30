{ config, lib, username, ... }:

let
  cfg = config.modules.home.thunar;
in
{
  options = {
    modules = {
      home = {
        thunar = {
          enable = lib.mkEnableOption "thunar file manager";
        };
      };
    };
  };

  # GTK 3 draws in software, so Thunar stays clear of the Mesa EGL crash
  # (get_back_bo dispatching Wayland events) that kept taking down
  # Nautilus's GTK 4 GL renderer. Trash and phones still come from gvfs.
  config = lib.mkIf cfg.enable {
    programs = {
      thunar = {
        enable = true;
      };
    };

    # Thumbnails; started over D-Bus only when a folder needs one.
    services = {
      tumbler = {
        enable = true;
      };
    };

    home-manager = {
      users = {
        ${username} = {
          # yazi is the keyboard-driven primary; thunar answers
          # "open folder" requests from other apps and covers DnD edge cases.
          xdg = {
            mimeApps = {
              defaultApplications = {
                "inode/directory" = [ "thunar.desktop" ];
              };
            };
          };

          xfconf = {
            settings = {
              thunar = {
                misc-show-delete-action = true;
                # Full date and time instead of "Today"/"Yesterday".
                misc-date-style = "THUNAR_DATE_STYLE_YYYYMMDD";
              };
            };
          };
        };
      };
    };
  };
}
