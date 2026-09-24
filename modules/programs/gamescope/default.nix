{ config, lib, ... }:

let
  cfg = config.modules.programs.gamescope;
in
{
  options = {
    modules = {
      programs = {
        gamescope = {
          enable = lib.mkEnableOption "gamescope nested compositor for games";
        };
      };
    };
  };

  # Per game, e.g. Steam launch options (niri wiki: --force-grab-cursor keeps
  # the pointer locked in the game):
  #   gamescope -f -W 2560 -H 1600 --force-grab-cursor -- nvidia-offload %command%
  # Offload the game inside gamescope, not gamescope itself: gamescope stays on
  # the iGPU that drives the panel and only the game wakes the RTX.
  config = lib.mkIf cfg.enable {
    programs = {
      gamescope = {
        enable = true;
        # The cap_sys_nice wrapper can't gain its capability under Steam's
        # bubblewrap (no_new_privs) and gamescope then fails to start;
        # gamemode already renices the game.
        capSysNice = false;
        # Nested under Wayland the default backend is wayland, which doesn't
        # lock the cursor in niri; SDL also is the only one that draws the
        # Steam overlay. A later --backend on the command line still wins.
        args = [
          "--backend"
          "sdl"
        ];
      };
    };
  };
}
