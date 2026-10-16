{ config, lib, ... }:

let
  cfg = config.modules.system.services.power-profiles-daemon;
in
{
  options = {
    modules = {
      system = {
        services = {
          power-profiles-daemon = {
            enable = lib.mkEnableOption "power-profiles-daemon";
          };
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    # With amd-pstate in active mode PPD drives EPP, boost and the governor.
    # ryukazed sets its profile from the EC shift mode (turbo on AC is
    # performance, eco on battery power-saver) and follows a profile picked in
    # Noctalia. "balanced" itself follows UPower's on-battery state
    # (balance_performance on AC, balance_power on battery). Keep
    # amd_dynamic_epp off: it fights PPD over EPP.
    services = {
      power-profiles-daemon = {
        enable = true;
      };
    };

    # nixpkgs only installs the unit and leaves PPD to D-Bus activation. Under
    # niri nothing is guaranteed to poke it, and until something does EPP never
    # follows the power source. graphical.target mirrors upstream's [Install];
    # multi-user.target would cycle with its After=multi-user.target.
    systemd = {
      services = {
        power-profiles-daemon = {
          wantedBy = [ "graphical.target" ];
        };
      };
    };

    warnings = lib.optional (!config.services.upower.enable) ''
      modules.system.services.power-profiles-daemon: UPower is disabled, so PPD
      cannot tell AC from battery and "balanced" stays at balance_performance.
    '';
  };
}
