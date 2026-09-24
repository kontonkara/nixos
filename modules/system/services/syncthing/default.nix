{ config, lib, username, ... }:

let
  cfg = config.modules.system.services.syncthing;
in
{
  options = {
    modules = {
      system = {
        services = {
          syncthing = {
            enable = lib.mkEnableOption "syncthing file synchronisation";
          };
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    services = {
      syncthing = {
        enable = true;
        # Runs as the user, so synced files are theirs; config, keys and the
        # database live in ~/.config/syncthing.
        user = username;
        group = "users";
        dataDir = "/home/${username}";
        # 22000/tcp+udp for sync, 21027/udp for LAN discovery.
        openDefaultPorts = true;
        # Devices and folders are added in the web UI (127.0.0.1:8384), so no
        # IDs land in the repo. Override would delete them as soon as any
        # declarative setting exists.
        overrideDevices = false;
        overrideFolders = false;
      };
    };
  };
}
