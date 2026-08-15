{ config, lib, ... }:

let
  cfg = config.modules.bluetooth;
in
{
  options.modules.bluetooth.enable = lib.mkEnableOption "Bluetooth support";

  config = lib.mkIf cfg.enable {
    hardware.bluetooth = {
      enable = true;
      powerOnBoot = false;
      settings = {
        General = {
          Experimental = true;
          FastConnectable = true;
        };
        Policy = {
          AutoEnable = true;
        };
      };
    };
  };
}
