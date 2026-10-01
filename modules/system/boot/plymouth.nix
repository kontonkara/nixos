{ config, lib, ... }:

{
  config = lib.mkIf config.modules.system.boot.enable {
    boot = {
      plymouth = {
        enable = true;
      };

      # A quiet boot behind the splash: no kernel, udev or systemd status
      # lines on the console, in the initrd (rd.*) or after it; all of it
      # still goes to the journal. loglevel 3 keeps kernel messages from
      # critical up (a panic, say) on screen. boot.initrd.verbose is left
      # alone: only the scripted initrd reads it, this one is systemd's.
      consoleLogLevel = 3;
      kernelParams = [
        "quiet"
        "udev.log_level=3"
        "rd.udev.log_level=3"
        "systemd.show_status=false"
        "rd.systemd.show_status=false"
      ];
    };
  };
}
