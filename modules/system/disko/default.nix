{ config, lib, ... }:

let
  cfg = config.modules.system.disko;

  # Already there while nixos-install copies the system in, so the store is
  # compressed from the start; hosts on this layout leave these mount points
  # out of storage.btrfs.mountPoints.
  mountOptions = [
    "noatime"
    "compress=zstd:1"
  ];
in
{
  options = {
    modules = {
      system = {
        disko = {
          enable = lib.mkEnableOption "the one-disk layout, partitioned by disko: an ESP and btrfs subvolumes on LUKS";

          device = lib.mkOption {
            type = lib.types.str;
            example = "/dev/disk/by-id/nvme-Samsung_SSD_980_PRO_1TB_S5GXNX0R000000A";
            description = "the whole disk to partition; by-id, so the name survives other disks coming and going.";
          };
        };
      };
    };
  };

  # The same layout alpha was set up with by hand, whose partitions disko
  # would not recognise (it mounts by its own partition labels), so alpha
  # keeps hardware.nix. The LUKS password is asked for while formatting.
  config = lib.mkIf cfg.enable {
    disko = {
      devices = {
        disk = {
          main = {
            type = "disk";
            inherit (cfg) device;
            content = {
              type = "gpt";
              partitions = {
                ESP = {
                  size = "1G";
                  type = "EF00";
                  content = {
                    type = "filesystem";
                    format = "vfat";
                    mountpoint = "/boot";
                    # bootctl warns the random seed on a world-readable ESP
                    # is a hole.
                    mountOptions = [
                      "fmask=0077"
                      "dmask=0077"
                    ];
                  };
                };
                system = {
                  size = "100%";
                  content = {
                    type = "luks";
                    name = "system";
                    settings = {
                      allowDiscards = true;
                    };
                    content = {
                      type = "btrfs";
                      extraArgs = [ "-f" ];
                      subvolumes = {
                        "@" = {
                          mountpoint = "/";
                          inherit mountOptions;
                        };
                        "@home" = {
                          mountpoint = "/home";
                          inherit mountOptions;
                        };
                        "@nix" = {
                          mountpoint = "/nix";
                          inherit mountOptions;
                        };
                        "@log" = {
                          mountpoint = "/var/log";
                          inherit mountOptions;
                        };
                      };
                    };
                  };
                };
              };
            };
          };
        };
      };
    };
  };
}
