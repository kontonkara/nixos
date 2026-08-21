{ config, lib, ... }:

let
  cfg = config.modules.services.sunshine;
in
{
  options = {
    modules = {
      services = {
        sunshine = {
          enable = lib.mkEnableOption "Sunshine game streaming";
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    services = {
      sunshine = {
        enable = true;
        openFirewall = true;
        capSysAdmin = true;
        autoStart = true;
      };
    };
  };
}
