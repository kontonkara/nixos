{ config, lib, inputs, username, ... }:

let
  cfg = config.modules.system.services.ryukaze;

  hm = config.home-manager.users.${username};
  hmStylix = hm.stylix;
  colors = hm.lib.stylix.colors;
  base = name: "#${colors.${name}}";
  # base05 at an alpha, as for yokoso: base16 has no muted foreground that
  # every scheme keeps readable on base00.
  faded = "#${colors.base05}b3";
  mode = if hmStylix.polarity == "light" then "light" else "dark";
in
{
  imports = [
    inputs.ryukaze.nixosModules.default
  ];

  options = {
    modules = {
      system = {
        services = {
          ryukaze = {
            enable = lib.mkEnableOption "ryukaze, the MSI EC daemon with its window and tray icon";

            chargeLimit = lib.mkOption {
              type = lib.types.nullOr (lib.types.ints.between 10 100);
              default = null;
              example = 80;
              description = ''
                battery charge end threshold in percent, or null to leave the
                EC alone. Charging resumes 10 points below it. The EC keeps it
                across reboots, so going back to null does not lift a limit:
                set 100.
              '';
            };
          };
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = config.modules.system.msi-ec.enable;
        message = "modules.system.services.ryukaze needs modules.system.msi-ec";
      }
    ];

    services = {
      # Fn+F9 sends e016, which the kernel has no key for: make it the
      # keyboard light key, for ryukaze's profiles.
      udev = {
        extraHwdb = ''
          evdev:atkbd:dmi:bvn*:bvr*:bd*:svnMicro-Star*:pnAlpha17C7V*:*
           KEYBOARD_KEY_96=kbdillumtoggle
        '';
      };

      ryukaze = {
        enable = true;
        users = [
          username
        ];
        tray = {
          enable = true;
        };
        # A card on screen when the modes change (Fn+F7, Fn+F8).
        osd = {
          enable = true;
        };
        # The desktop's palette, accent and font in the window.
        theme = lib.mkIf hmStylix.enable {
          inherit mode;
          font = hmStylix.fonts.sansSerif.name;
          ${mode} = {
            background = base "base00";
            card = base "base01";
            border = base "base02";
            text = base "base05";
            muted = faded;
            idle = base "base02";
            hover = base "base03";
            strong = base config.modules.home.stylix.accent;
            on_strong = base "base00";
            track = base "base03";
            track_hover = base "base04";
            knob = faded;
            danger = base "base08";
          };
        };
        settings = {
          # On AC the performance scenario (turbo, auto fans, super battery
          # off); on battery eco with super battery. ryukazed leaves super
          # battery before raising the shift mode and enters it after lowering
          # it, and keeps power-profiles-daemon in step with the shift mode.
          profiles = {
            ac = {
              scenario = "performance";
            };
            battery = {
              shift_mode = "eco";
              fan_mode = "auto";
              super_battery = true;
            };
          };
          # Cooler boost by itself past 95 °C (CPU) or 85 °C (GPU).
          cooler_boost = {
            auto = true;
          };
          # Fn+F9 steps through these. #ff6000 is the stylix accent (#fab387) as
          # the keyboard's LEDs show it, matched by eye: they turn pastel
          # shades white and make blue strong. The numpad dark without NumLock.
          keyboard = {
            numpad_follows_numlock = true;
            profiles = [
              {
                name = "static";
                color = "#ff6000";
              }
              {
                name = "breathe";
                effect = "breathe";
                color = "#ff6000";
              }
              {
                name = "wave";
                effect = "wave";
              }
              {
                name = "reactive";
                effect = "reactive";
                color = "#301000";
                flash = "#ffffff";
              }
            ];
          };
        }
        // lib.optionalAttrs (cfg.chargeLimit != null) {
          charge_limit = cfg.chargeLimit;
        };
      };
    };
  };
}
