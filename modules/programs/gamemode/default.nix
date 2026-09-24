{ config, lib, ... }:

let
  cfg = config.modules.programs.gamemode;
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
          # No [gpu]: its NVIDIA path shells out to nvidia-settings (X11 +
          # Coolbits), which can't work on niri with PRIME offload. No
          # softrealtime: SCHED_ISO isn't in mainline kernels.
        };
      };
    };
  };
}
