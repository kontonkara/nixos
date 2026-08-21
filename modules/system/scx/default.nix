{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.modules.scx;
in
{
  options.modules.scx = {
    enable = lib.mkEnableOption "sched_ext scheduler testing through scx-loader";

    defaultScheduler = lib.mkOption {
      type = lib.types.nullOr (
        lib.types.enum [
          "scx_beerland"
          "scx_bpfland"
          "scx_cake"
          "scx_cosmos"
          "scx_flash"
          "scx_flow"
          "scx_forge"
          "scx_lavd"
          "scx_p2dq"
          "scx_pandemonium"
          "scx_rustland"
          "scx_rusty"
          "scx_tickless"
        ]
      );
      default = null;
      description = "Scheduler started at boot, or null to retain the kernel fair scheduler until a manual test.";
    };

    defaultMode = lib.mkOption {
      type = lib.types.enum [
        "Auto"
        "Gaming"
        "LowLatency"
        "PowerSave"
        "Server"
      ];
      default = "Auto";
      description = "Initial scx-loader mode when a default scheduler is configured.";
    };
  };

  config = lib.mkIf cfg.enable {
    services.scx-loader = {
      enable = true;
      schedsPackages = [ pkgs.scx.rustscheds ];
      config = {
        default_sched = cfg.defaultScheduler;
        default_mode = cfg.defaultMode;
      };
    };
  };
}
