{ config, lib, username, ... }:

let
  cfg = config.modules.home.xdg;
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
        };
      };
    };
  };
}
