{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.modules.power;

  msiEcModes = {
    high-performance = {
      shiftMode = "turbo";
      fanMode = "auto";
      superBattery = "off";
    };
    balanced = {
      shiftMode = "comfort";
      fanMode = "auto";
      superBattery = "off";
    };
    silent = {
      shiftMode = "comfort";
      fanMode = "silent";
      superBattery = "off";
    };
    super-battery = {
      shiftMode = "eco";
      fanMode = "auto";
      superBattery = "on";
    };
  };

  acMsiEcMode = msiEcModes.${cfg.msiEc.acMode};
  batteryMsiEcMode = msiEcModes.${cfg.msiEc.batteryMode};

  msiEcShiftModePath = "/sys/devices/platform/msi-ec/shift_mode";
  msiEcFanModePath = "/sys/devices/platform/msi-ec/fan_mode";
  msiEcSuperBatteryPath = "/sys/devices/platform/msi-ec/super_battery";

  applyDisplayPowerProfile = pkgs.writeShellApplication {
    name = "apply-display-power-profile";
    runtimeInputs = [ pkgs.kdePackages.libkscreen ];
    text = ''
      if [[ -z "''${WAYLAND_DISPLAY:-}" || -z "''${XDG_RUNTIME_DIR:-}" ]]; then
        exit 0
      fi

      mains_online=0

      for supply in /sys/class/power_supply/*; do
        if [[ -r "$supply/type" && -r "$supply/online" ]]; then
          read -r supply_type < "$supply/type"
          read -r supply_online < "$supply/online"

          if [[ "$supply_type" == "Mains" && "$supply_online" == "1" ]]; then
            mains_online=1
            break
          fi
        fi
      done

      if ((mains_online)); then
        desired_abm_level=${toString cfg.display.acAbmLevel}
      else
        desired_abm_level=${toString cfg.display.batteryAbmLevel}
      fi

      if ! kscreen-doctor ${lib.escapeShellArg "output.${cfg.display.connector}.abm"}."$desired_abm_level"; then
        echo "unable to apply adaptive backlight modulation to ${lib.escapeShellArg cfg.display.connector}" >&2
      fi
    '';
  };

  applyPowerProfile = pkgs.writeShellApplication {
    name = "apply-power-profile";
    runtimeInputs = [
      pkgs.power-profiles-daemon
      pkgs.systemd
    ];
    text = ''
      mains_online=0

      for supply in /sys/class/power_supply/*; do
        if [[ -r "$supply/type" && -r "$supply/online" ]]; then
          read -r supply_type < "$supply/type"
          read -r supply_online < "$supply/online"

          if [[ "$supply_type" == "Mains" && "$supply_online" == "1" ]]; then
            mains_online=1
            break
          fi
        fi
      done

      if ((mains_online)); then
        desired_profile=${lib.escapeShellArg cfg.acProfile}
        ${lib.optionalString cfg.msiEc.enable ''
          desired_shift_mode=${lib.escapeShellArg acMsiEcMode.shiftMode}
          desired_fan_mode=${lib.escapeShellArg acMsiEcMode.fanMode}
          desired_super_battery=${lib.escapeShellArg acMsiEcMode.superBattery}
        ''}
      else
        desired_profile=${lib.escapeShellArg cfg.batteryProfile}
        ${lib.optionalString cfg.msiEc.enable ''
          desired_shift_mode=${lib.escapeShellArg batteryMsiEcMode.shiftMode}
          desired_fan_mode=${lib.escapeShellArg batteryMsiEcMode.fanMode}
          desired_super_battery=${lib.escapeShellArg batteryMsiEcMode.superBattery}
        ''}
      fi

      apply_profile() {
        if [[ "$(powerprofilesctl get)" != "$desired_profile" ]]; then
          powerprofilesctl set "$desired_profile"
        fi
      }

      ${lib.optionalString cfg.display.enable ''
        notify_graphical_sessions() {
          declare -A notified_users=()

          while read -r session _rest; do
            [[ "$(loginctl show-session "$session" --property=Active --value)" == "yes" ]] || continue
            [[ "$(loginctl show-session "$session" --property=Remote --value)" == "no" ]] || continue
            [[ "$(loginctl show-session "$session" --property=Type --value)" == "wayland" ]] || continue

            session_user="$(loginctl show-session "$session" --property=Name --value)"
            [[ -n "$session_user" ]] || continue
            [[ -z "''${notified_users[$session_user]:-}" ]] || continue
            notified_users[$session_user]=1

            systemctl --machine="$session_user@.host" --user start apply-display-power-profile.service || true
          done < <(loginctl list-sessions --no-legend --no-pager)
        }
      ''}

      ${lib.optionalString cfg.msiEc.enable ''
        apply_ec_value() {
          path="$1"
          desired_value="$2"
          setting_name="$3"

          if [[ ! -r "$path" || ! -w "$path" ]]; then
            echo "msi-ec $setting_name is enabled, but $path is unavailable" >&2
            return 1
          fi

          read -r current_value < "$path"

          if [[ "$current_value" != "$desired_value" ]]; then
            printf '%s\n' "$desired_value" > "$path"
          fi
        }
      ''}

      if ((mains_online)); then
        ${lib.optionalString cfg.msiEc.enable ''
          apply_ec_value ${lib.escapeShellArg msiEcSuperBatteryPath} "$desired_super_battery" super-battery
          apply_ec_value ${lib.escapeShellArg msiEcFanModePath} "$desired_fan_mode" fan-mode
          apply_ec_value ${lib.escapeShellArg msiEcShiftModePath} "$desired_shift_mode" shift-mode
        ''}
        apply_profile
      else
        apply_profile
        ${lib.optionalString cfg.msiEc.enable ''
          apply_ec_value ${lib.escapeShellArg msiEcShiftModePath} "$desired_shift_mode" shift-mode
          apply_ec_value ${lib.escapeShellArg msiEcFanModePath} "$desired_fan_mode" fan-mode
          apply_ec_value ${lib.escapeShellArg msiEcSuperBatteryPath} "$desired_super_battery" super-battery
        ''}
      fi

      ${lib.optionalString cfg.display.enable ''
        notify_graphical_sessions
      ''}
    '';
  };
in
{
  options = {
    modules = {
      power = {
        enable = lib.mkEnableOption "automatic power profiles";

        acProfile = lib.mkOption {
          type = lib.types.enum [
            "power-saver"
            "balanced"
            "performance"
          ];
          default = "performance";
          description = "Power profile used while mains power is connected.";
        };

        batteryProfile = lib.mkOption {
          type = lib.types.enum [
            "power-saver"
            "balanced"
            "performance"
          ];
          default = "power-saver";
          description = "Power profile used while discharging the battery.";
        };

        msiEc = {
          enable = lib.mkEnableOption "MSI EC shift-mode switching";

          acMode = lib.mkOption {
            type = lib.types.enum [
              "high-performance"
              "balanced"
              "silent"
              "super-battery"
            ];
            default = "high-performance";
            description = "Composite MSI EC mode used while mains power is connected.";
          };

          batteryMode = lib.mkOption {
            type = lib.types.enum [
              "high-performance"
              "balanced"
              "silent"
              "super-battery"
            ];
            default = "super-battery";
            description = "Composite MSI EC mode used while discharging the battery.";
          };
        };

        display = {
          enable = lib.mkEnableOption "power-source-aware adaptive backlight modulation";

          connector = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            description = "KScreen connector name that receives the adaptive backlight level.";
          };

          acAbmLevel = lib.mkOption {
            type = lib.types.ints.between 0 4;
            default = 0;
            description = "Adaptive backlight modulation level used while mains power is connected.";
          };

          batteryAbmLevel = lib.mkOption {
            type = lib.types.ints.between 0 4;
            default = 4;
            description = "Adaptive backlight modulation level used while discharging the battery.";
          };
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = !cfg.display.enable || cfg.display.connector != null;
        message = "modules.power.display.connector must be set when display power management is enabled";
      }
    ];

    services = {
      acpid = {
        enable = true;
        acEventCommands = lib.getExe applyPowerProfile;
      };

      power-profiles-daemon.enable = true;
    };

    systemd.services.apply-power-profile = {
      description = "Apply the power profile for the current power source";
      wantedBy = [ "graphical.target" ];
      after = [
        "power-profiles-daemon.service"
        "systemd-modules-load.service"
      ];
      requires = [ "power-profiles-daemon.service" ];

      serviceConfig = {
        Type = "oneshot";
        ExecStart = lib.getExe applyPowerProfile;
      };
    };

    systemd.user.services.apply-display-power-profile = lib.mkIf cfg.display.enable {
      description = "Apply the display power profile for the current power source";
      wantedBy = [ "graphical-session.target" ];
      after = [ "plasma-kwin_wayland.service" ];
      partOf = [ "graphical-session.target" ];

      environment.QT_QPA_PLATFORM = "wayland";

      serviceConfig = {
        Type = "oneshot";
        ExecStart = lib.getExe applyDisplayPowerProfile;
      };
    };
  };
}
