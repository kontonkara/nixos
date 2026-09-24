{ config, lib, ... }:

let
  cfg = config.modules.system.memory;
in
{
  options = {
    modules = {
      system = {
        memory = {
          enable = lib.mkEnableOption "zram swap and oom handling";
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    zramSwap = {
      enable = true;
      algorithm = "zstd";
      # Caps the uncompressed size; RAM is only used for pages actually swapped.
      memoryPercent = 50;
      priority = 5;
    };

    boot = {
      kernel = {
        sysctl = {
          # Swapping to zram is cheap, so prefer it over dropping page cache
          # (>100 is meant for in-memory swap), and skip swap readahead.
          "vm.swappiness" = 180;
          "vm.page-cluster" = 0;
        };
      };

      # CachyOS builds zswap on by default; in front of zram every swapped page
      # would be compressed twice (its own udev rule that turns zswap off is
      # a CachyOS-distro file NixOS doesn't have).
      kernelParams = [ "zswap.enabled=0" ];

      # Nix 2.34 builds in /nix/var/nix/builds, so /tmp only holds small
      # scratch files; RAM is only used for what's actually there.
      tmp = {
        useTmpfs = true;
        tmpfsSize = "20%";
      };
    };

    # oomd runs but watches no cgroups by default; let it act on user slices
    # before the whole desktop stalls under memory pressure.
    systemd = {
      oomd = {
        enableUserSlices = true;
      };
    };
  };
}
