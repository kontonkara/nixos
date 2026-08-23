{ config, lib, ... }:

let
  cfg = config.modules.network;
in
{
  options = {
    modules = {
      network = {
        enable = lib.mkEnableOption "NetworkManager";

        wifi = {
          lowLatency = {
            enable = lib.mkEnableOption "low-latency Wi-Fi power settings";
          };
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    networking = {
      networkmanager = {
        enable = true;
        wifi = {
          powersave = lib.mkIf cfg.wifi.lowLatency.enable false;
        };
      };
    };

    boot.extraModprobeConfig = lib.optionalString cfg.wifi.lowLatency.enable ''
      options iwlwifi power_save=0
      options iwlmvm power_scheme=1
    '';
  };
}
