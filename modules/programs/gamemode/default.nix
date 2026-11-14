{ config, lib, pkgs, ... }:

let
  cfg = config.modules.programs.gamemode;

  # The performance power profile while a game runs, on AC only, and the one
  # before it afterwards. ryukazed keeps the EC's shift mode in step with
  # power-profiles-daemon, so this is turbo for the game and back.
  powerProfile = pkgs.writeShellApplication {
    name = "gamemode-power-profile";
    runtimeInputs = [ pkgs.power-profiles-daemon ];
    text = ''
      saved="''${XDG_RUNTIME_DIR:-/tmp}/gamemode-power-profile"

      case "$1" in
        start)
          for supply in /sys/class/power_supply/*; do
            if [ "$(cat "$supply/type")" = Mains ] && [ "$(cat "$supply/online")" = 1 ]; then
              powerprofilesctl get > "$saved"
              powerprofilesctl set performance
              break
            fi
          done
          ;;
        end)
          if [ -f "$saved" ]; then
            powerprofilesctl set "$(cat "$saved")"
            rm "$saved"
          fi
          ;;
      esac
    '';
  };
in
{
  options = {
    modules = {
      programs = {
        gamemode = {
          enable = lib.mkEnableOption "feral gamemode";
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    programs = {
      gamemode = {
        enable = true;

        settings = {
          general = {
            # 0..20, applied negated (old configs' -10 was rejected as invalid).
            renice = 10;
          };
          # At the first game's start and after the last one's end.
          custom = {
            start = "${lib.getExe powerProfile} start";
            end = "${lib.getExe powerProfile} end";
          };
          # No [gpu]: its NVIDIA path shells out to nvidia-settings (X11 +
          # Coolbits), which can't work on niri with PRIME offload. No
          # softrealtime: SCHED_ISO isn't in mainline kernels.
        };
      };
    };
  };
}
