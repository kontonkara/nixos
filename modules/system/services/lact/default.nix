{ config, lib, ... }:

let
  cfg = config.modules.system.services.lact;
in
{
  options = {
    modules = {
      system = {
        services = {
          lact = {
            enable = lib.mkEnableOption "LACT GPU monitoring and control daemon";

            gpus = lib.mkOption {
              type = lib.types.attrsOf lib.types.anything;
              default = { };
              example = {
                "10DE:2820-1462:13ED-0000:01:00.0" = {
                  gpu_clock_offsets = {
                    "0" = 200;
                  };
                };
              };
              description = ''
                LACT's settings per GPU, by the id `lact cli list` prints (the
                keys of the GUI's /etc/lact/config.yaml). Once set, the config
                is a read-only store link: the GUI's changes still apply, but
                only until lactd restarts.
              '';
            };
          };
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    services = {
      lact = {
        enable = true;
        settings = lib.mkIf (cfg.gpus != { }) {
          # lactd migrates an older schema and writes the file back at
          # start, which fails on the store link: keep the current one.
          version = 7;
          daemon = {
            log_level = "info";
            admin_group = "wheel";
          };
          inherit (cfg) gpus;
        };
      };
    };
  };
}
