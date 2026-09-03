{ config, lib, ... }:

let
  cfg = config.modules.services.timesyncd;
in
{
  options = {
    modules = {
      services = {
        timesyncd = {
          enable = lib.mkEnableOption "systemd network time synchronisation";
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    services = {
      timesyncd = {
        enable = true;

        servers = [
          "time.cloudflare.com"
          "time1.google.com"
          "time2.google.com"
          "time3.google.com"
          "time4.google.com"
        ];

        fallbackServers = [
          "0.nixos.pool.ntp.org"
          "1.nixos.pool.ntp.org"
          "2.nixos.pool.ntp.org"
          "3.nixos.pool.ntp.org"
        ];
      };
    };
  };
}
