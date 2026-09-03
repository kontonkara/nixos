{ config, lib, ... }:

let
  cfg = config.modules.services.lact;
in
{
  options = {
    modules = {
      services = {
        lact = {
          enable = lib.mkEnableOption "LACT GPU monitoring and control service";
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    services = {
      lact = {
        enable = true;
      };
    };
  };
}
