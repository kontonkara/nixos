{ config, lib, ... }:

let
  cfg = config.modules.system.services.tinysparql;
in
{
  options = {
    modules = {
      system = {
        services = {
          tinysparql = {
            enable = lib.mkEnableOption "tinysparql metadata store";
          };
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    services = {
      gnome = {
        tinysparql = {
          enable = true;
        };
      };
    };
  };
}
