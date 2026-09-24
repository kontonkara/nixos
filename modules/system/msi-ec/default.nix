{ config, lib, pkgs, ... }:

let
  cfg = config.modules.system.msi-ec;

  applyEnabled = cfg.chargeThreshold != null || cfg.modes.enable;

  # Every name msi-ec knows. The script also checks the target against the
  # running firmware's available_shift_modes / available_fan_modes
  # (17KKIMS1.115: eco comfort turbo / auto silent advanced).
  shiftModes = [
    "eco"
    "comfort"
    "sport"
    "turbo"
  ];
  fanModes = [
    "auto"
    "silent"
    "basic"
    "advanced"
  ];

  mkModeOptions = source: defaults: {
    shiftMode = lib.mkOption {
      type = lib.types.enum shiftModes;
      default = defaults.shiftMode;
      description = "EC shift mode (CPU/GPU power preset) while on ${source}.";
    };

    fanMode = lib.mkOption {
      type = lib.types.enum fanModes;
      default = defaults.fanMode;
      description = "EC fan mode while on ${source}.";
    };

    superBattery = lib.mkOption {
      type = lib.types.bool;
      default = defaults.superBattery;
      description = "EC super-battery mode while on ${source}.";
    };
  };

  onOff = value: if value then "on" else "off";

  chargeThreshold = if cfg.chargeThreshold == null then "" else toString cfg.chargeThreshold;
  rearmDelay = if cfg.modes.rearmTurbo.enable then toString cfg.modes.rearmTurbo.delay else "";

  apply = pkgs.writeShellApplication {
    name = "msi-ec-apply";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.gnugrep
    ];
    text = builtins.readFile ./apply.sh;
  };

  # restart, not start: a start merges into a run already in progress and
  # would drop the newer event.
  restartApply = "${config.systemd.package}/bin/systemctl --no-block restart msi-ec-apply.service";
in
{
  options = {
    modules = {
      system = {
        msi-ec = {
          enable = lib.mkEnableOption "the upstream msi-ec embedded controller driver";

          chargeThreshold = lib.mkOption {
            type = lib.types.nullOr (lib.types.ints.between 10 100);
            default = null;
            example = 80;
            description = ''
              battery charge end threshold in percent, or null to leave the EC
              alone. The EC only stores the end threshold; charging resumes 10
              points below it. The EC keeps the value across reboots, so going
              back to null does not lift a limit: set 100 instead.
            '';
          };

          modes = {
            enable = lib.mkEnableOption "switching EC shift/fan/super-battery modes by power source";

            ac = mkModeOptions "AC" {
              shiftMode = "turbo";
              fanMode = "auto";
              superBattery = false;
            };

            battery = mkModeOptions "battery" {
              shiftMode = "eco";
              fanMode = "auto";
              superBattery = true;
            };

            # Unverified observation on this EC (17KKIMS1.115), never
            # upstreamed: turbo on AC did not always take effect until the EC
            # was cycled through comfort + fan auto + super-battery off.
            # Only acts when the AC shift mode is turbo.
            rearmTurbo = {
              enable = lib.mkEnableOption "passing through comfort before applying turbo on AC";

              delay = lib.mkOption {
                type = lib.types.ints.between 1 10;
                default = 1;
                description = "seconds to hold comfort before switching to turbo.";
              };
            };
          };
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    boot = {
      extraModulePackages = [
        (config.boot.kernelPackages.callPackage ../../../pkgs/msi-ec { })
      ];

      # msi-ec has no modalias, so nothing autoloads it.
      kernelModules = [
        "msi-ec"
      ];
    };

    # Re-run on AC plug/unplug, when ac.ko registers ADP1 after the boot run,
    # and when the driver (re)binds.
    services = {
      udev = {
        extraRules = lib.mkIf applyEnabled ''
          SUBSYSTEM=="power_supply", ENV{POWER_SUPPLY_TYPE}=="Mains", ACTION=="add|change", RUN+="${restartApply}"
          SUBSYSTEM=="platform", KERNEL=="msi-ec", ACTION=="bind", RUN+="${restartApply}"
        '';
      };
    };

    systemd = {
      services = {
        msi-ec-apply = lib.mkIf applyEnabled {
          description = "Apply MSI EC charge threshold and power-source modes";
          # Deliberately not ordered against power-profiles-daemon: PPD only
          # writes cpufreq (EPP/boost/governor) and msi-ec exposes no
          # platform_profile, so they never touch the same knob. PPD's unit is
          # also After=multi-user.target, so After=PPD here would be a cycle.
          wantedBy = [ "multi-user.target" ];
          after = [ "systemd-modules-load.service" ];

          # Plug/unplug bursts must not trip the start rate limit.
          startLimitIntervalSec = 0;

          environment = {
            MSI_EC_CHARGE_THRESHOLD = chargeThreshold;
            MSI_EC_MODES = if cfg.modes.enable then "1" else "0";
            MSI_EC_AC_SHIFT_MODE = cfg.modes.ac.shiftMode;
            MSI_EC_AC_FAN_MODE = cfg.modes.ac.fanMode;
            MSI_EC_AC_SUPER_BATTERY = onOff cfg.modes.ac.superBattery;
            MSI_EC_BATTERY_SHIFT_MODE = cfg.modes.battery.shiftMode;
            MSI_EC_BATTERY_FAN_MODE = cfg.modes.battery.fanMode;
            MSI_EC_BATTERY_SUPER_BATTERY = onOff cfg.modes.battery.superBattery;
            MSI_EC_REARM_TURBO_DELAY = rearmDelay;
          };

          serviceConfig = {
            Type = "oneshot";
            ExecStart = lib.getExe apply;
          };
        };
      };
    };
  };
}
