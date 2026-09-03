{ config, lib, ... }:

let
  cfg = config.modules.programs.gamemode;
in
{
  options = {
    modules = {
      programs = {
        gamemode = {
          enable = lib.mkEnableOption "GameMode on-demand system optimisation";
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
            renice = -10;
            softrealtime = "auto";
            inhibit_screensaver = 1;
            ioprio = 0;
          };

          gpu = {
            apply_gpu_optimisations = "accept-responsibility";
            gpu_device = 1;
            nv_powermizer_mode = 1;
          };
        };
      };
    };
  };
}
