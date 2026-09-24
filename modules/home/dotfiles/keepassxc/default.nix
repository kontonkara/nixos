{ config, lib, pkgs, inputs, username, ... }:

let
  cfg = config.modules.home.keepassxc;

  hmConfig = config.home-manager.users.${username};
  hmStylix = hmConfig.stylix;
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

          # Its default "auto" theme, like light and dark, replaces the Qt
          # style and palette with its own; classic keeps stylix's Kvantum
          # (through qt5ct, it's a Qt 5 build). Only this key is set, into the
          # writable ini. A running KeePassXC merges the file when it saves
          # and only writes the key from its View > Theme menu; the theme
          # applies on its next start.
          home = {
            activation = {
              keepassxcTheme = lib.mkIf (hmStylix.enable && hmStylix.targets.qt.enable) (
                inputs.home-manager.lib.hm.dag.entryAfter [ "writeBoundary" ] ''
                  run mkdir -p "${hmConfig.xdg.configHome}/keepassxc"
                  run ${lib.getExe pkgs.crudini} --ini-options=nospace --set \
                    "${hmConfig.xdg.configHome}/keepassxc/keepassxc.ini" GUI ApplicationTheme classic
                ''
              );
            };
          };
        };
      };
    };
  };
}
