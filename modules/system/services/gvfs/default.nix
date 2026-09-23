{ config, lib, ... }:

let
  cfg = config.modules.system.services.gvfs;
in
{
  options = {
    modules = {
      system = {
        services = {
          gvfs = {
            enable = lib.mkEnableOption "gvfs virtual filesystem backends";
          };
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    services = {
      gvfs = {
        enable = true;
      };
    };
  };
}
