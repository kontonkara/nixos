{ config, lib, ... }:

let
  cfg = config.modules.system.scx;
in
{
  options = {
    modules = {
      system = {
        scx = {
          enable = lib.mkEnableOption "sched_ext schedulers through scx-loader";

          scheduler = lib.mkOption {
            type = lib.types.str;
            default = "scx_cake";
            description = "scheduler started at boot; switch at runtime with `scxctl switch --sched <name>`.";
          };
        };
      };
    };
  };

  # scx-loader rather than services.scx: schedulers can be swapped over
  # D-Bus without a rebuild, and it falls back to EEVDF if one gets ejected.
  config = lib.mkIf cfg.enable {
    services = {
      scx-loader = {
        enable = true;
        config = {
          default_sched = cfg.scheduler;
        };
      };
    };
  };
}
