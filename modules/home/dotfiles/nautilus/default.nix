{ config, lib, pkgs, username, ... }:

let
  cfg = config.modules.home.nautilus;
in
{
  options = {
    modules = {
      home = {
        nautilus = {
          enable = lib.mkEnableOption "nautilus file manager";
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
              pkgs.nautilus
            ];
          };

          # yazi is the keyboard-driven primary; nautilus answers
          # "open folder" requests from other apps and covers DnD edge cases.
          xdg = {
            mimeApps = {
              defaultApplications = {
                "inode/directory" = [ "org.gnome.Nautilus.desktop" ];
              };
            };
          };

          # No default-folder-viewer: nautilus saves the view toggle there,
          # so pinning it would undo that on every activation. Hidden files
          # and directories-first come from org/gtk/gtk4/settings/file-chooser.
          dconf = {
            settings = {
              "org/gnome/nautilus/preferences" = {
                # Context-menu entries that are hidden by default.
                show-create-link = true;
                show-delete-permanently = true;
                # Full date and time instead of "Today"/"Yesterday".
                date-time-format = "detailed";
              };
            };
          };
        };
      };
    };
  };
}
