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

    # Nothing on a laptop should wait for a connection, least of all sing-box,
    # the system's DNS: its package's unit is ordered after
    # network-online.target, and a drop-in can't remove that. With this wait
    # it started ~10 s into the boot, up to 60 s without Wi-Fi.
    systemd = {
      services = {
        NetworkManager-wait-online = {
          enable = false;
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
