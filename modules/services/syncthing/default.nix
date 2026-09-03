{
  config,
  lib,
  username,
  ...
}:

let
  cfg = config.modules.services.syncthing;
in
{
  options = {
    modules = {
      services = {
        syncthing = {
          enable = lib.mkEnableOption "Syncthing continuous file synchronisation";
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    services = {
      syncthing = {
        enable = true;
        user = username;
        dataDir = "/home/${username}";
        configDir = "/home/${username}/.config/syncthing";
      };
    };
  };
}
