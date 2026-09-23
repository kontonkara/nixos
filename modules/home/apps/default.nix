{ config, lib, username, inputs, pkgs, ... }:

let
  cfg = config.modules.home.apps;
in
{
  options = {
    modules = {
      home = {
        apps = {
          enable = lib.mkEnableOption "home applications";
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    home-manager = {
      users = {
        ${username} = {
          home = {
            packages = with pkgs; [
              tree
              telegram-desktop
              keepassxc
              nautilus
              inputs.llm-agents.packages.x86_64-linux.mimo-code
            ];
          };

          # yazi is the keyboard-driven primary; nautilus answers
          # "open folder" requests from other apps and covers DnD edge cases.
          xdg.mimeApps.defaultApplications = {
            "inode/directory" = [ "nautilus.desktop" ];
          };
        };
      };
    };
  };
}
