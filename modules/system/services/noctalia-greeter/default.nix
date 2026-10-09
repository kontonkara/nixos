{ config, lib, username, ... }:

let
  cfg = config.modules.system.services.noctalia-greeter;

  hmConfig = config.home-manager.users.${username};
  hmStylix = hmConfig.stylix;
  noctalia = hmConfig.programs.noctalia;

  # The shell's own palette, as stylix's noctalia target builds it (accent
  # included), under the greeter's role names.
  shellTheme = noctalia.settings.theme;
  shellPalette = noctalia.customPalettes.${shellTheme.custom_palette}.${shellTheme.mode};
  palette = lib.mapAttrs (_role: key: shellPalette.${key}) {
    primary = "mPrimary";
    on_primary = "mOnPrimary";
    secondary = "mSecondary";
    on_secondary = "mOnSecondary";
    tertiary = "mTertiary";
    on_tertiary = "mOnTertiary";
    error = "mError";
    on_error = "mOnError";
    surface = "mSurface";
    on_surface = "mOnSurface";
    surface_variant = "mSurfaceVariant";
    on_surface_variant = "mOnSurfaceVariant";
    outline = "mOutline";
    shadow = "mShadow";
    hover = "mHover";
    on_hover = "mOnHover";
  };
  syncedLook = hmStylix.enable && hmStylix.targets.noctalia.enable;
in
{
  options = {
    modules = {
      system = {
        services = {
          noctalia-greeter = {
            enable = lib.mkEnableOption "noctalia greeter on greetd, dressed like the shell";
          };
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    services = {
      displayManager = {
        noctalia-greeter = {
          enable = true;

          cursorTheme = lib.mkIf hmStylix.enable {
            inherit (hmStylix.cursor) package name;
          };

          # greeter.toml, a read-only store link. Noctalia's own Sync (off in
          # its settings) and the login screen only write sync.toml, which
          # this file wins over.
          settings = lib.mkMerge [
            {
              # Straight to the password step: the only account here.
              user = {
                default = username;
              };

              # The console's layout (us): the password is typed in that one
              # anyway, and a switched layout can't get in the way.
              keyboard = {
                inherit (config.services.xserver.xkb) layout;
              };

              cursor = lib.mkIf hmStylix.enable {
                inherit (hmStylix.cursor) size;
              };
            }

            (lib.mkIf config.modules.home.niri.enable {
              # The desktop entry's Name=, not its file name.
              session = {
                default = "Niri";
              };
            })

            # The shell's look: palette, theme mode, corner scale and font. A
            # plain background in the surface color, since Noctalia's
            # wallpapers live in the home directory the greeter can't read.
            # No scheme picker: it could only switch away from this palette.
            (lib.mkIf syncedLook {
              appearance = {
                scheme = "Synced";
                scheme_selector_position = "hidden";
                theme_mode = shellTheme.mode;
                corner_radius_scale = noctalia.settings.shell.corner_radius_scale;
                font_family = hmStylix.fonts.sansSerif.name;
                inherit palette;
                wallpaper = {
                  fill_color = palette.surface;
                };
              };
            })
          ];
        };
      };
    };
  };
}
