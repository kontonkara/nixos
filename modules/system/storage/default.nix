{
  config,
  lib,
  utils,
  ...
}:

let
  cfg = config.modules.storage;

  btrfsMountOptions =
    lib.optional (cfg.btrfs.compression != null) "compress=${cfg.btrfs.compression}"
    ++ lib.optional cfg.btrfs.noAtime "noatime";

  scrubServiceName = mountPoint: "btrfs-scrub-${utils.escapeSystemdPath mountPoint}";
in
{
  options = {
    modules = {
      storage = {
        enable = lib.mkEnableOption "SSD and Btrfs storage tuning";

        btrfs = {
          mountPoints = lib.mkOption {
            type = lib.types.listOf lib.types.path;
            default = [ ];
            description = "Btrfs mount points that receive the configured mount options.";
          };

          compression = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = "zstd:1";
            description = "Btrfs compression algorithm and level, or null to disable compression.";
          };

          noAtime = lib.mkOption {
            type = lib.types.bool;
            default = true;
            description = "Disable access-time updates on the configured Btrfs mount points.";
          };

          scrub = {
            enable = lib.mkOption {
              type = lib.types.bool;
              default = true;
              description = "Periodically verify Btrfs checksums.";
            };

            fileSystems = lib.mkOption {
              type = lib.types.listOf lib.types.path;
              default = [ ];
              description = "One mount point per Btrfs filesystem to scrub.";
            };

            interval = lib.mkOption {
              type = lib.types.str;
              default = "monthly";
              description = "Systemd calendar expression used for Btrfs scrub timers.";
            };

            limit = lib.mkOption {
              type = lib.types.nullOr (lib.types.strMatching "[0-9]+[KMGT]?");
              default = "500M";
              description = "Maximum scrub throughput per filesystem, or null for no limit.";
            };
          };
        };

        luks = {
          devices = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [ ];
            description = "LUKS device names that receive the configured performance options.";
          };

          bypassWorkqueues = lib.mkOption {
            type = lib.types.bool;
            default = true;
            description = "Bypass dm-crypt read and write workqueues on fast SSDs.";
          };

          allowDiscards = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = "Allow discard requests through dm-crypt, with the associated allocation-pattern leak.";
          };
        };

        maintenanceOnACOnly = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Run scheduled TRIM and Btrfs scrub only while mains power is connected.";
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    fileSystems = lib.genAttrs cfg.btrfs.mountPoints (_mountPoint: {
      options = btrfsMountOptions;
    });

    boot = {
      initrd = {
        luks = {
          devices = lib.genAttrs cfg.luks.devices (_device: {
            inherit (cfg.luks) allowDiscards bypassWorkqueues;
          });
        };
      };
    };

    services = {
      fstrim = {
        enable = true;
      };

      btrfs = {
        autoScrub = {
          inherit (cfg.btrfs.scrub)
            enable
            fileSystems
            interval
            limit
            ;
        };
      };
    };

    systemd.services = lib.mkIf cfg.maintenanceOnACOnly (
      {
        fstrim.unitConfig.ConditionACPower = true;
      }
      // lib.optionalAttrs cfg.btrfs.scrub.enable (
        lib.listToAttrs (
          map (mountPoint: {
            name = scrubServiceName mountPoint;
            value.unitConfig.ConditionACPower = true;
          }) cfg.btrfs.scrub.fileSystems
        )
      )
    );
  };
}
