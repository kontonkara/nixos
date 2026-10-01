{ config, lib, ... }:

let
  cfg = config.modules.system.watchdog;

  # Manager.RuntimeWatchdogUSec over D-Bus, to disarm the watchdog around sleep.
  setRuntimeWatchdog =
    usec:
    "${config.systemd.package}/bin/busctl set-property org.freedesktop.systemd1"
    + " /org/freedesktop/systemd1 org.freedesktop.systemd1.Manager RuntimeWatchdogUSec t ${usec}";
in
{
  options = {
    modules = {
      system = {
        watchdog = {
          enable = lib.mkEnableOption "the hardware watchdog and rebooting on kernel hangs";
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    # systemd pings the chipset's SP5100 TCO timer; when the whole system
    # hangs and the pings stop, the timer resets the machine. A GPU hang that
    # leaves the kernel running doesn't trip it.
    systemd = {
      settings = {
        Manager = {
          RuntimeWatchdogSec = "30s";
        };
      };
    };

    # s2idle keeps the timer counting while nothing pings it, so it is
    # disarmed for sleep and armed again on resume.
    powerManagement = {
      powerDownCommands = setRuntimeWatchdog "0";
      resumeCommands = setRuntimeWatchdog "30000000";
    };

    boot = {
      kernel = {
        sysctl = {
          # A soft lockup panics instead of only being logged, so efi_pstore
          # keeps its trace (systemd-pstore archives it on the next boot)...
          "kernel.softlockup_panic" = 1;
          # ...and a panic reboots after 10 s instead of hanging there.
          "kernel.panic" = 10;
        };
      };
    };
  };
}
