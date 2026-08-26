{ config, lib, ... }:

let
  cfg = config.modules.memory;
in
{
  options = {
    modules = {
      memory = {
        enable = lib.mkEnableOption "RAM, zram and virtual-memory tuning";

        transparentHugePages = {
          mode = lib.mkOption {
            type = lib.types.enum [
              "always"
              "madvise"
              "never"
            ];
            default = "always";
            description = "Global transparent huge-page allocation policy.";
          };
        };

        zram = {
          enable = lib.mkOption {
            type = lib.types.bool;
            default = true;
            description = "Use compressed RAM as swap and disable the redundant zswap layer.";
          };

          algorithm = lib.mkOption {
            type = lib.types.either (
              lib.types.enum [
                "842"
                "lzo"
                "lzo-rle"
                "lz4"
                "lz4hc"
                "zstd"
              ]
            ) lib.types.str;
            default = "zstd";
            description = ''
              Compression algorithm specification used by zram-generator.
              A string may contain a primary compressor, secondary recompression
              algorithms and their parameters.
            '';
          };

          memoryPercent = lib.mkOption {
            type = lib.types.ints.between 1 200;
            default = 50;
            description = "Maximum uncompressed zram size as a percentage of physical RAM.";
          };

          priority = lib.mkOption {
            type = lib.types.ints.between (-1) 32767;
            default = 5;
            description = "Swap priority assigned to the zram device.";
          };
        };

        tmpfs = {
          enable = lib.mkOption {
            type = lib.types.bool;
            default = true;
            description = "Back /tmp with tmpfs.";
          };

          size = lib.mkOption {
            type = lib.types.str;
            default = "20%";
            description = "Maximum size of the /tmp tmpfs.";
          };
        };

        virtualMemory = {
          swappiness = lib.mkOption {
            type = lib.types.ints.between 0 200;
            default = 180;
            description = "Relative cost assigned to zram swap versus filesystem paging.";
          };

          pageCluster = lib.mkOption {
            type = lib.types.ints.between 0 31;
            default = 0;
            description = "Logarithmic swap read-ahead size.";
          };

          vfsCachePressure = lib.mkOption {
            type = lib.types.ints.unsigned;
            default = 50;
            description = "Relative reclaim pressure applied to inode and dentry caches.";
          };

          dirtyRatio = lib.mkOption {
            type = lib.types.ints.between 0 100;
            default = 15;
            description = "Percentage of eligible memory at which writers perform writeback.";
          };

          dirtyBackgroundRatio = lib.mkOption {
            type = lib.types.ints.between 0 100;
            default = 5;
            description = "Percentage of eligible memory at which background writeback starts.";
          };

          maxMapCount = lib.mkOption {
            type = lib.types.ints.positive;
            default = 1048576;
            description = ''
              Maximum number of virtual-memory mappings per process. The NixOS
              default leaves ample headroom without effectively disabling the
              kernel's per-process VMA resource guard.
            '';
          };

          minFreeKbytes = lib.mkOption {
            type = lib.types.ints.positive;
            default = 524288;
            description = "Minimum free-memory reserve in KiB.";
          };

          watermarkBoostFactor = lib.mkOption {
            type = lib.types.ints.unsigned;
            default = 0;
            description = "Fragmentation-driven reclaim boost in ten-thousandths.";
          };

          watermarkScaleFactor = lib.mkOption {
            type = lib.types.ints.between 1 3000;
            default = 125;
            description = "Distance between memory watermarks in ten-thousandths.";
          };

          compactionProactiveness = lib.mkOption {
            type = lib.types.ints.between 0 100;
            default = 0;
            description = "Aggressiveness of proactive background memory compaction.";
          };
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    boot = {
      kernelParams = lib.mkOrder 910 (
        [ "transparent_hugepage=${cfg.transparentHugePages.mode}" ]
        ++ lib.optional cfg.zram.enable "zswap.enabled=0"
      );

      kernel.sysctl = {
        "vm.swappiness" = cfg.virtualMemory.swappiness;
        "vm.page-cluster" = cfg.virtualMemory.pageCluster;
        "vm.vfs_cache_pressure" = cfg.virtualMemory.vfsCachePressure;
        "vm.dirty_ratio" = cfg.virtualMemory.dirtyRatio;
        "vm.dirty_background_ratio" = cfg.virtualMemory.dirtyBackgroundRatio;
        "vm.max_map_count" = cfg.virtualMemory.maxMapCount;
        "vm.min_free_kbytes" = cfg.virtualMemory.minFreeKbytes;
        "vm.watermark_boost_factor" = cfg.virtualMemory.watermarkBoostFactor;
        "vm.watermark_scale_factor" = cfg.virtualMemory.watermarkScaleFactor;
        "vm.compaction_proactiveness" = cfg.virtualMemory.compactionProactiveness;
      };

      tmp = lib.mkIf cfg.tmpfs.enable {
        useTmpfs = true;
        tmpfsSize = cfg.tmpfs.size;
      };
    };

    zramSwap = lib.mkIf cfg.zram.enable {
      enable = true;
      inherit (cfg.zram) algorithm memoryPercent priority;
    };
  };
}
