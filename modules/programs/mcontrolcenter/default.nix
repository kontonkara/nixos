{ config, lib, pkgs, username, ... }:

let
  cfg = config.modules.programs.mcontrolcenter;

  package = pkgs.mcontrolcenter.overrideAttrs (old: {
    patches = (old.patches or [ ]) ++ [
      # Follow the EC's mode (msi-ec-apply switches it by power source)
      # instead of re-applying the app's saved one.
      ./mcontrolcenter-sync-external-profile.patch
      # Advanced fan mode through msi-ec; the checkbox follows the EC.
      ./mcontrolcenter-fan-mode.patch
    ];
    # The helper writes any EC byte as root on request and upstream lets
    # every local user call it; only the desktop user needs to.
    postPatch = (old.postPatch or "") + ''
      substituteInPlace src/helper/mcontrolcenter-helper.conf \
        --replace-fail '<policy context="default">' '<policy user="${username}">'
    '';
  });
in
{
  options = {
    modules = {
      programs = {
        mcontrolcenter = {
          enable = lib.mkEnableOption "MControlCenter, the MSI EC tray app";
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        # Without msi-ec the app falls back to raw EC addresses it guesses.
        assertion = config.modules.system.msi-ec.enable;
        message = "modules.programs.mcontrolcenter needs modules.system.msi-ec";
      }
    ];

    # Also registers the root helper's system bus policy and activation file:
    # the dbus module already lists system-path in services.dbus.packages.
    environment = {
      systemPackages = [
        package
      ];
    };

    # Starts hidden in the tray; launching it again opens the window. A Home
    # Manager unit keeps the session's PATH (xdg-open for the About links).
    home-manager = {
      users = {
        ${username} = {
          systemd = {
            user = {
              services = {
                mcontrolcenter = {
                  Unit = {
                    Description = "MControlCenter tray";
                    PartOf = [ "graphical-session.target" ];
                    After = [ "graphical-session.target" ];
                    # Only while msi-ec is bound and exposes the charge limit:
                    # otherwise the app guesses raw EC addresses and can write
                    # the charge limit to one at start-up (e.g. after an EC
                    # firmware update msi-ec does not know yet).
                    ConditionPathExists = [
                      "/sys/devices/platform/msi-ec/fw_version"
                      "/sys/class/power_supply/BAT1/charge_control_end_threshold"
                    ];
                  };

                  # No wait for Noctalia: on Wayland Qt always uses SNI and
                  # registers the icon again once a StatusNotifierWatcher
                  # appears.
                  Service = {
                    ExecStart = lib.getExe package;
                  };

                  Install = {
                    WantedBy = [ "graphical-session.target" ];
                  };
                };
              };
            };
          };
        };
      };
    };
  };
}
