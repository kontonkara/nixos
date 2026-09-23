{ config, lib, ... }:

let
  cfg = config.modules.system.services.udisks2;
in
{
  options = {
    modules = {
      system = {
        services = {
          udisks2 = {
            enable = lib.mkEnableOption "udisks2 disk management service";
          };
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    services = {
      udisks2 = {
        enable = true;
      };
    };
  };
}
