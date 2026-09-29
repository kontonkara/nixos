{ config, lib, ... }:

let
  cfg = config.modules.system.network;
in
{
  options = {
    modules = {
      system = {
        network = {
          enable = lib.mkEnableOption "networkmanager";
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    networking = {
      networkmanager = {
        enable = true;
        wifi = {
          # iwlwifi's power save puts latency spikes into every link,
          # Moonlight streams over Wi-Fi included; costs a little battery.
          powersave = false;
        };
      };
    };

    boot = {
      # Everything leaves through sing-box, whose outbound TCP to the remote
      # server is the kernel's; BBR holds throughput on long, lossy paths
      # where cubic backs off, and paces best on fq.
      kernelModules = [ "tcp_bbr" ];

      kernel = {
        sysctl = {
          # Only kicks in once a path silently drops full-size segments (ICMP
          # black hole); the sing-box VLESS/WS tunnel would otherwise stall there.
          "net.ipv4.tcp_mtu_probing" = 1;
          "net.ipv4.tcp_congestion_control" = "bbr";
          "net.core.default_qdisc" = "fq";
        };
      };
    };
  };
}
