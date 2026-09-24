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
      };
    };

    # Only kicks in once a path silently drops full-size segments (ICMP
    # black hole); the sing-box VLESS/WS tunnel would otherwise stall there.
    boot = {
      kernel = {
        sysctl = {
          "net.ipv4.tcp_mtu_probing" = 1;
        };
      };
    };
  };
}
