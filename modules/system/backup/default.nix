{ config, lib, pkgs, inputs, username, ... }:

let
  cfg = config.modules.system.backup;

  # The top level (subvolid 5) of cfg.device, where btrbk sees the
  # subvolumes by name and keeps its snapshots beside them.
  pool = "/.btrfs";
in
{
  options = {
    modules = {
      system = {
        backup = {
          enable = lib.mkEnableOption "hourly btrfs snapshots sent to a second disk (btrbk)";

          device = lib.mkOption {
            type = lib.types.str;
            example = "/dev/mapper/system";
            description = "btrfs device holding the subvolumes; its top level is mounted at ${pool}.";
          };

          subvolumes = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            example = [ "@home" ];
            description = "subvolumes, relative to the top level, to snapshot and send.";
          };

          target = lib.mkOption {
            type = lib.types.str;
            example = "/data/backups/alpha";
            description = "directory on another btrfs filesystem that receives the snapshots.";
          };

          homeSubvolumes = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [ ];
            example = [ ".cache" ];
            description = "paths under the user's home kept as nested subvolumes, which snapshots of the home subvolume leave out.";
          };
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    fileSystems = {
      ${pool} = {
        inherit (cfg) device;
        fsType = "btrfs";
        options = [
          "subvolid=5"
          "noatime"
          "compress=zstd:1"
        ];
      };
    };

    # btrbk creates neither the snapshot directory nor the target.
    systemd = {
      tmpfiles = {
        rules = [
          "d ${pool}/@snapshots 0755 root root -"
          "d ${cfg.target} 0700 root root -"
        ];
      };

      services = {
        # The target is on a volume opened after boot (nofail); fail the run
        # instead of writing into the empty mount point.
        btrbk-btrbk = {
          unitConfig = {
            RequiresMountsFor = [
              pool
              cfg.target
            ];
          };
        };
      };
    };

    # Runs as the user, so missing parents get the user's ownership and no
    # root is needed (btrfs lets owners create subvolumes). An existing plain
    # directory is only reported: turning it into a subvolume means moving
    # its data while apps (Steam) may be using it.
    home-manager = {
      users = {
        ${username} = { config, ... }: {
          home = {
            activation = {
              backupHomeSubvolumes = lib.mkIf (cfg.homeSubvolumes != [ ]) (
                inputs.home-manager.lib.hm.dag.entryAfter [ "writeBoundary" ] ''
                  if [ "$(stat -f -c %T "$HOME")" = btrfs ]; then
                    for path in ${
                      lib.escapeShellArgs (map (path: "${config.home.homeDirectory}/${path}") cfg.homeSubvolumes)
                    }; do
                      if [ ! -e "$path" ]; then
                        run mkdir -p "$(dirname "$path")"
                        run ${pkgs.btrfs-progs}/bin/btrfs subvolume create "$path"
                      elif [ "$(stat -c %i "$path")" != 256 ]; then
                        warnEcho "$path is a plain directory, so /home snapshots still include it"
                      fi
                    done
                  fi
                ''
              );
            };
          };
        };
      };
    };

    services = {
      btrbk = {
        # Stays out of the way of the desktop, like the nix daemon.
        ioSchedulingClass = "idle";
        niceness = 19;

        instances = {
          btrbk = {
            # 00:00, 04:00, …; the timer is Persistent, so a run missed while
            # the laptop was off happens at the next boot.
            onCalendar = "*-*-* 00/4:00:00";
            settings = {
              # Several snapshots a day need the time in their names.
              timestamp_format = "long";

              # On the same disk (against rm and bad edits): every snapshot
              # of the last 2 days, then one a day for 2 weeks.
              snapshot_preserve_min = "2d";
              snapshot_preserve = "14d";

              # On the second disk (against losing the first): one a day for
              # 2 weeks, one a week for 2 months, one a month for half a year.
              # btrbk only sends what the target keeps, so "latest" is what
              # makes every run send its snapshot, not just the day's first.
              target_preserve_min = "latest";
              target_preserve = "14d 8w 6m";

              volume = {
                ${pool} = {
                  snapshot_dir = "@snapshots";
                  subvolume = lib.genAttrs cfg.subvolumes (_subvolume: { });
                  inherit (cfg) target;
                };
              };
            };
          };
        };
      };
    };
  };
}
