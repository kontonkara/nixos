{ config, lib, ... }:

let
  cfg = config.modules.network;
in
{
  options = {
    modules = {
      network = {
        enable = lib.mkEnableOption "NetworkManager and host networking policy";

        wifi = {
          lowLatency = {
            enable = lib.mkEnableOption "low-latency Wi-Fi power settings";
          };
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    boot = {
      kernelModules = [ "tcp_bbr" ];

      kernel.sysctl = {
        "net.core.default_qdisc" = "fq";
        "net.core.rmem_max" = 16777216;
        "net.core.wmem_max" = 16777216;
        "net.ipv4.tcp_rmem" = "4096 87380 16777216";
        "net.ipv4.tcp_wmem" = "4096 65536 16777216";
        "net.ipv4.tcp_congestion_control" = "bbr";
        "net.ipv4.tcp_fastopen" = 3;
        "net.ipv4.tcp_mtu_probing" = 1;
      };

      extraModprobeConfig = lib.optionalString cfg.wifi.lowLatency.enable ''
        options iwlwifi power_save=0
        options iwlmvm power_scheme=1
      '';
    };

    networking = {
      networkmanager = {
        enable = true;
        wifi = {
          powersave = lib.mkIf cfg.wifi.lowLatency.enable false;
        };
      };
    };
  };
}
