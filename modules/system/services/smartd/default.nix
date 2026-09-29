{ config, lib, ... }:

let
  cfg = config.modules.system.services.smartd;
in
{
  options = {
    modules = {
      system = {
        services = {
          smartd = {
            enable = lib.mkEnableOption "smartd disk health monitoring with desktop notifications";
          };
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    services = {
      smartd = {
        enable = true;
        # Every disk it finds (autodetect), with all SMART/NVMe health checks.
        notifications = {
          # To the desktop (Noctalia) through systembus-notify, which runs as
          # the user; its spam risk is other local users, and there are none.
          systembus-notify = {
            enable = true;
          };

          # xmessage on an X display; niri has none of its own.
          x11 = {
            enable = false;
          };
        };
      };
    };
  };
}
