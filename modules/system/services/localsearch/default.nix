{ config, lib, ... }:

let
  cfg = config.modules.system.services.localsearch;
in
{
  options = {
    modules = {
      system = {
        services = {
          localsearch = {
            enable = lib.mkEnableOption "localsearch file indexer";
          };
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    services = {
      gnome = {
        localsearch = {
          enable = true;
        };
      };
    };
  };
}
