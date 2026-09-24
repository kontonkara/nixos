{ config, lib, ... }:

let
  cfg = config.modules.system.storage;
in
{
  options = {
    modules = {
      system = {
        storage = {
          enable = lib.mkEnableOption "ssd and btrfs storage tuning";

          btrfs = {
            mountPoints = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              default = [ ];
              description = "btrfs mount points that get noatime (a per-mount vfs flag, so list every one).";
            };

            scrub = {
              fileSystems = lib.mkOption {
                type = lib.types.listOf lib.types.str;
                default = [ ];
                description = "one mount point per btrfs filesystem to scrub monthly.";
              };
            };
          };

          luks = {
            discardDevices = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              default = [ ];
              description = "initrd luks devices that pass discards through dm-crypt (leaks the free-block pattern, not data).";
            };
          };
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    fileSystems = lib.genAttrs cfg.btrfs.mountPoints (_mountPoint: {
      options = [ "noatime" ];
    });

    boot = {
      initrd = {
        luks = {
          devices = lib.genAttrs cfg.luks.discardDevices (_device: {
            allowDiscards = true;
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
          enable = cfg.btrfs.scrub.fileSystems != [ ];
          inherit (cfg.btrfs.scrub) fileSystems;
          interval = "monthly";
        };
      };

      # CachyOS's elevator patch gives multi-queue NVMe mq-deadline instead
      # of upstream's none (its distro ships a udev rule NixOS lacks).
      udev = {
        extraRules = ''
          ACTION=="add|change", KERNEL=="nvme[0-9]*n[0-9]*", ATTR{queue/scheduler}="none"
        '';
      };
    };

    # Keep weekly trim and monthly scrubs off the battery.
    systemd = {
      services = {
        fstrim = {
          unitConfig = {
            ConditionACPower = true;
          };
        };

        "btrfs-scrub@" = {
          unitConfig = {
            ConditionACPower = true;
          };
        };
      };
    };
  };
}
