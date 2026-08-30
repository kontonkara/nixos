{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.modules.scx;

  scxRustScheds =
    if lib.versionAtLeast pkgs.scx.rustscheds.version "1.1.3" then
      pkgs.scx.rustscheds
    else
      pkgs.scx.rustscheds.overrideAttrs (oldAttrs: rec {
        version = "1.1.3";

        src = pkgs.fetchFromGitHub {
          owner = "sched-ext";
          repo = "scx";
          tag = "v${version}";
          hash = "sha256-LK0go5blWgCtDpS5xm9BQc7C2NvbfrW+Jp66ImIThxA=";
        };

        cargoHash = "sha256-vEsbpor52DEUpYO5OubFPMzRltO5kUXjqAoO/9hsKXc=";
        cargoDeps = pkgs.rustPlatform.fetchCargoVendor {
          inherit src;
          name = "scx_rustscheds-${version}-vendor";
          hash = cargoHash;
        };

        passthru = oldAttrs.passthru // {
          schedulers = lib.sort builtins.lessThan (oldAttrs.passthru.schedulers ++ [ "scx_mlfq" ]);
        };

        env = oldAttrs.env // {
          EXPECTED_SCHEDULERS = lib.concatStringsSep " " passthru.schedulers;
        };
      });
in
{
  options = {
    modules = {
      scx = {
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
    };
  };

  config = lib.mkIf cfg.enable {
    services.scx-loader = {
      enable = true;
      schedsPackages = [ scxRustScheds ];
      config = {
        default_sched = cfg.defaultScheduler;
        default_mode = cfg.defaultMode;
      };
    };
  };
}
