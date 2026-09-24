{ config, lib, username, ... }:

let
  cfg = config.modules.home.keepassxc;
in
{
  options = {
    modules = {
      home = {
        keepassxc = {
          enable = lib.mkEnableOption "keepassxc password manager";
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    home-manager = {
      users = {
        ${username} = {
          programs = {
            # Installs the Firefox native-messaging host. No settings: HM
            # would make keepassxc.ini a read-only store link. Its SSH agent
            # and Secret Service stay off; gcr-ssh-agent and gnome-keyring
            # already provide them.
            keepassxc = {
              enable = true;
            };
          };
        };
      };
    };
  };
}
