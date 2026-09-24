{ config, lib, username, ... }:

let
  cfg = config.modules.home.xdg;

  hmXdg = config.home-manager.users.${username}.xdg;
  hmStylix = config.home-manager.users.${username}.stylix;
in
{
  options = {
    modules = {
      home = {
        xdg = {
          enable = lib.mkEnableOption "xdg user dirs and mime";
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    home-manager = {
      users = {
        ${username} = {
          xdg = {
            enable = true;

            userDirs = {
              enable = true;
              createDirectories = true;

              desktop = "$HOME/desktop";
              documents = "$HOME/documents";
              download = "$HOME/downloads";
              music = "$HOME/music";
              pictures = "$HOME/pictures";
              videos = "$HOME/videos";
              templates = "$HOME/templates";
              publicShare = "$HOME/public";
              # HM has a first-class option now; its ~/Projects default was
              # being created on every switch.
              projects = "$HOME/projects";
            };

            mimeApps.enable = true;
          };

          home = {
            # For the Home Manager modules that support it: gtk2
            # (~/.gtkrc-2.0 moves to ~/.config/gtk-2.0/gtkrc, GTK2_RC_FILES
            # follows) and kubecolor (~/.kube/color.yaml).
            preferXdgDirectories = true;

            # Cursor links also go to ~/.local/share/icons, and the theme sits
            # in the per-user profile, both on XCURSOR_PATH. Setting any
            # pointerCursor option would switch Home Manager's cursor config
            # on even without a cursor to configure.
            pointerCursor = lib.mkIf (hmStylix.enable && hmStylix.cursor != null) {
              dotIcons = {
                enable = false;
              };
            };

            sessionVariables = {
              # For interactive bash started from fish; a file directly in the
              # state dir needs no directory created first.
              HISTFILE = "${hmXdg.stateHome}/bash_history";
            };
          };

          # Nothing loads it at login under niri; Home Manager only merges it
          # into a running X server on activation.
          xresources = {
            path = "${hmXdg.configHome}/X11/xresources";
          };
        };
      };
    };
  };
}
