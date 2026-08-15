{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.modules.power;

  applyPowerProfile = pkgs.writeShellApplication {
    name = "apply-power-profile";
    runtimeInputs = [ pkgs.power-profiles-daemon ];
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
      else
        desired_profile=${lib.escapeShellArg cfg.batteryProfile}
      fi

      if [[ "$(powerprofilesctl get)" != "$desired_profile" ]]; then
        powerprofilesctl set "$desired_profile"
      fi
    '';
  };
in
{
  options.modules.power = {
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
  };

  config = lib.mkIf cfg.enable {
    services = {
      acpid = {
        enable = true;
        acEventCommands = lib.getExe applyPowerProfile;
      };

      power-profiles-daemon.enable = true;
    };

    systemd.services.apply-power-profile = {
      description = "Apply the power profile for the current power source";
      wantedBy = [ "multi-user.target" ];
      after = [ "power-profiles-daemon.service" ];
      requires = [ "power-profiles-daemon.service" ];

      serviceConfig = {
        Type = "oneshot";
        ExecStart = lib.getExe applyPowerProfile;
      };
    };
  };
}
