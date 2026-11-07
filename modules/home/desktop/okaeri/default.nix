{ config, lib, inputs, username, ... }:

let
  cfg = config.modules.home.okaeri;

  hmConfig = config.home-manager.users.${username};
  hmStylix = hmConfig.stylix;
  colors = hmConfig.lib.stylix.colors;
  # base05 at an alpha, as for yokoso: base16 has no muted foreground.
  faded = alpha: "#${alpha}${colors.base05}";
in
{
  options = {
    modules = {
      home = {
        okaeri = {
          enable = lib.mkEnableOption "okaeri desktop shell";
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    # okaeri is the polkit agent; two registered agents would race for every
    # prompt.
    systemd = {
      user = {
        services = {
          niri-flake-polkit = {
            enable = false;
          };
        };
      };
    };

    home-manager = {
      users = {
        ${username} = {
          imports = [
            inputs.okaeri.homeManagerModules.default
          ];

          programs = {
            okaeri = {
              enable = true;
              # The desktop's palette, accent and font.
              theme = lib.mkMerge [
                {
                  radius = 8;
                  barHeight = 38;
                  blur = true;
                  barBlur = true;
                  toastBlur = true;
                  realBlur = true;
                }
                (lib.mkIf hmStylix.enable {
                  extends = if hmStylix.polarity == "light" then "light" else "dark";
                  colors = {
                    background = "#${colors.base00}";
                    surface = "#${colors.base02}";
                    text = "#${colors.base05}";
                    subtext = faded "b3";
                    dim = faded "80";
                    accent = "#${colors.${config.modules.home.stylix.accent}}";
                    error = "#${colors.base08}";
                  };
                  font = hmStylix.fonts.sansSerif.name;
                })
              ];
              settings = {
                tray = {
                  drawer = true;
                };
                wallpaper = {
                  backdrop = true;
                  path = "${hmConfig.home.homeDirectory}/pictures/wallpapers/clouds-3.jpg";
                };
              };
            };
          };
        };
      };
    };
  };
}
