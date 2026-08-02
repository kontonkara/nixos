{ pkgs, ... }:

{

  imports = [
    ./plymouth.nix
  ];

  boot = {
    kernelPackages = pkgs.linuxPackages_xanmod_latest;

    kernelModules = [
      "msi-ec"
      "ryzen_smu"
      "ntsync"
      "ec_sys"
      "tcp_bbr"
      "ath12k"
      "kvm-amd"
    ];

    kernelParams = [
      "preempt=full"
      "mitigations=off"
      "split_lock_mitigate=0"
      "amd_pstate=active"
      "amd_pstate.prefcore=1"
      "nvme_core.default_ps_max_latency_us=5500"
      "amdgpu.ppfeaturemask=0xffffffff"
      "amdgpu.gttsize=8192"
      "amdgpu.freesync_video=1"
      "amdgpu.sg_display=0"
      "amdgpu.dcdebugmask=0x10"
      "transparent_hugepage=always"
      "nowatchdog"
      "nvidia_drm.modeset=1"
      "nvidia_drm.fbdev=1"
      "nvidia.NVreg_EnableResizableBar=1"
      "nvidia.NVreg_RegistryDwords=PowerMizerEnable=0x1"
      "iommu=pt"
      "acpi_backlight=native"
    ];

    kernel.sysctl = {
      "vm.swappiness" = 180;
      "vm.dirty_ratio" = 15;
      "vm.dirty_background_ratio" = 5;
      "vm.max_map_count" = 2147483642;
      "vm.min_free_kbytes" = 524288;
      "vm.vfs_cache_pressure" = 50;
      "vm.page-cluster" = 0;
      "vm.watermark_boost_factor" = 0;
      "vm.watermark_scale_factor" = 125;
      "vm.compaction_proactiveness" = 0;
      "kernel.nmi_watchdog" = 0;
      "net.core.default_qdisc" = "fq";
      "net.core.rmem_max" = 16777216;
      "net.core.wmem_max" = 16777216;
      "net.ipv4.tcp_rmem" = "4096 87380 16777216";
      "net.ipv4.tcp_wmem" = "4096 65536 16777216";
      "net.ipv4.tcp_low_latency" = 1;
      "net.ipv4.tcp_congestion_control" = "bbr";
      "net.ipv4.tcp_fastopen" = 3;
      "net.ipv4.tcp_mtu_probing" = 1;
      "fs.file-max" = 2097152;
    };

    tmp = {
      useTmpfs = true;
      tmpfsSize = "20%";
    };

    extraModprobeConfig = "options ec_sys write_support=1";

    loader = {
      timeout = 3;
      systemd-boot = {
        enable = true;
        configurationLimit = 7;
        editor = false;
      };
      efi = {
        canTouchEfiVariables = true;
      };
    };

    initrd = {
      luks = {
        devices = {
          "data".keyFile = "/etc/secrets/data.key";
        };
      };
      secrets = {
        "/etc/secrets/data.key" = "/etc/secrets/data.key";
      };
    };
  };

  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 50;
  };
}
