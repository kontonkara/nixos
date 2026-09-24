{ config, lib, ... }:

let
  cfg = config.modules.system.bluetooth;
in
{
  options = {
    modules = {
      system = {
        bluetooth = {
          enable = lib.mkEnableOption "Bluetooth support";
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    hardware = {
      bluetooth = {
        enable = true;
        settings = {
          General = {
            Experimental = true;
            # ISO socket only (not every kernel experiment): LE Audio's BAP
            # profile needs it and bluetoothd logged it as missing.
            KernelExperimental = "6fbaf188-05e0-496a-9885-d6ddfdb4e03e";
            FastConnectable = true;
          };
          Policy = {
            AutoEnable = true;
          };
        };
      };
    };
  };
}
