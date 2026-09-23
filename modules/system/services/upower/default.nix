{ config, lib, ... }:

let
  cfg = config.modules.system.services.upower;
in
{
  options = {
    modules = {
      system = {
        services = {
          upower = {
            enable = lib.mkEnableOption "upower power-supply service";
          };
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    services = {
      upower = {
        enable = true;
      };
    };
  };
}
