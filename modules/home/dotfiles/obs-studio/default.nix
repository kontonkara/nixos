{ config, lib, pkgs, inputs, username, ... }:

let
  cfg = config.modules.home.obs-studio;

  hmConfig = config.home-manager.users.${username};

  # Catppuccin's theme for OBS 30.2+: a base theme and a style per flavor.
  catppuccin = pkgs.fetchFromGitHub {
    owner = "catppuccin";
    repo = "obs";
    rev = "054a297d303a5bac4f1652a13b17d78a13201c0e";
    hash = "sha256-zFg7dgxLIK3K1KpLdEgphH2JpdMwVTovr+oKiAqdLEE=";
  };
  theme = "com.obsproject.Catppuccin.Mocha.Peach";
in
{
  options = {
    modules = {
      home = {
        obs-studio = {
          enable = lib.mkEnableOption "obs studio";
        };
      };
    };
  };

  # Screen capture is "Screen Capture (PipeWire)" via the gnome portal.
  # Every launch briefly wakes the RTX: obs-nvenc probes NVENC in a
  # subprocess (obs-nvenc-test), and the AV1 VAAPI probe moves on to
  # renderD129 because the 610M has no AV1 encoder. NVENC needs no
  # nvidia-offload but keeps the RTX awake while recording; the VAAPI
  # H.264/HEVC encoders on renderD128 (610M) leave it asleep.
  # No virtual camera: that is the NixOS module's v4l2loopback, an
  # out-of-tree module rebuilt against the local kernel.
  config = lib.mkIf cfg.enable {
    home-manager = {
      users = {
        ${username} = {
          programs = {
            obs-studio = {
              enable = true;
              plugins = [
                # Per-application audio sources (a game without Vesktop's
                # voice); stock OBS on Linux only captures whole devices.
                pkgs.obs-studio-plugins.obs-pipewire-audio-capture
              ];
            };
          };

          # OBS loads user themes from the files directly in themes/.
          xdg = {
            configFile = {
              "obs-studio/themes/Catppuccin.obt" = {
                source = "${catppuccin}/themes/Catppuccin.obt";
              };
              "obs-studio/themes/Catppuccin_Mocha.ovt" = {
                source = "${catppuccin}/themes/Catppuccin_Mocha.ovt";
              };
              # Catppuccin's accent is blue with lavender for hover and focus,
              # and nothing else uses those two; this style turns them into
              # peach and rosewater.
              "obs-studio/themes/Catppuccin_Mocha_Peach.ovt" = {
                text = ''
                  @OBSThemeMeta {
                      name: 'Mocha Peach';
                      id: '${theme}';
                      extends: 'com.obsproject.Catppuccin.Mocha';
                      dark: 'true';
                  }

                  @OBSThemeVars {
                      --ctp_blue: var(--ctp_peach);
                      --ctp_lavender: var(--ctp_rosewater);
                  }
                '';
              };
            };
          };

          # The theme choice is a key in user.ini, which OBS keeps rewriting,
          # so only that key is set. OBS writes the file from memory when it
          # quits, which undoes a switch made while it's open until the next.
          home = {
            activation = {
              obsTheme = inputs.home-manager.lib.hm.dag.entryAfter [ "writeBoundary" ] ''
                run mkdir -p "${hmConfig.xdg.configHome}/obs-studio"
                run ${lib.getExe pkgs.crudini} --ini-options=nospace --set \
                  "${hmConfig.xdg.configHome}/obs-studio/user.ini" Appearance Theme ${theme}
              '';
            };
          };
        };
      };
    };
  };
}
