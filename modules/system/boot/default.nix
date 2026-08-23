{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.modules.boot;

  baseKernelPackages = pkgs.linuxPackages_cachyos-lto-znver4;
  kernelConfigOverrides = config.modules.graphics.amd.kernel.cachyosConfigOverrides;
  kernelConfigArgs = lib.concatMap (
    name:
    let
      value = kernelConfigOverrides.${name};
      action =
        if value == "y" then
          "-e"
        else if value == "m" then
          "-m"
        else
          "-d";
    in
    [
      action
      (lib.removePrefix "CONFIG_" name)
    ]
  ) (builtins.attrNames kernelConfigOverrides);
  compilerKernelPackages =
    if config.modules.ccache.enable then
      baseKernelPackages.cachyOverride {
        stdenv = config.modules.ccache.wrapStdenv baseKernelPackages.kernel.stdenv;
      }
    else
      baseKernelPackages;
  kernelPackages = compilerKernelPackages.extend (
    _final: previous:
    lib.optionalAttrs (kernelConfigOverrides != { }) {
      kernel = previous.kernel.overrideAttrs (oldAttrs: {
        postConfigure = (oldAttrs.postConfigure or "") + ''
          cp "$buildRoot/.config" "$buildRoot/.config.mutable"
          mv "$buildRoot/.config.mutable" "$buildRoot/.config"
          scripts/config --file "$buildRoot/.config" ${lib.escapeShellArgs kernelConfigArgs}
          make "''${makeFlags[@]}" olddefconfig
        '';
      });
    }
  );

  msiEc = {
    rev = "050d4394a6747ebd106ae2f8ddb3a4eebe7c700f";
    hash = "sha256-b7wwZstjeLPEsxIjmZentDwkQTxdBYbpJfdOR24Ofww=";
  };

  ryzenSmu = {
    rev = "1be4fb1cd9d60b5ddefc2a4201a898766a731400";
    hash = "sha256-Tj3MZBDtobXAdF07DmqEnaJWCoJ0Xkbn25jqAIWAfoc=";
  };

  ryzenCurveOptimizerOffset = "0xFFFEC"; # CO -20
  applyRyzenCurveOptimizer = "${pkgs.ryzenadj}/bin/ryzenadj --set-coall=${ryzenCurveOptimizerOffset}";

in
{
  imports = [
    ./plymouth.nix
  ];

  options = {
    modules = {
      boot = {
        enable = lib.mkEnableOption "alpha boot and kernel configuration";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    boot = {
      inherit kernelPackages;

      kernelModules = [
        "msi-ec"
        "ryzen_smu"
        "ntsync"
        "ec_sys"
        "tcp_bbr"
        "kvm-amd"
      ];

      extraModulePackages = [
        (config.boot.kernelPackages.msi-ec.overrideAttrs (_oldAttrs: {
          src = pkgs.fetchFromGitHub {
            owner = "BeardOverflow";
            repo = "msi-ec";
            inherit (msiEc) rev hash;
          };
          patches = [ ];
          postPatch = ''
            substituteInPlace Makefile \
              --replace-fail '/lib/modules/$(KERNELRELEASE)/build' '${config.boot.kernelPackages.kernel.dev}/lib/modules/${config.boot.kernelPackages.kernel.modDirVersion}/build'
          '';
          installTargets = [ "modules" ];
          postInstall = ''
            dest=$out/lib/modules/${config.boot.kernelPackages.kernel.modDirVersion}/updates
            mkdir -p $dest
            cp msi-ec.ko $dest/
          '';
        }))
        (config.boot.kernelPackages.ryzen-smu.overrideAttrs (oldAttrs: {
          src = pkgs.fetchFromGitHub {
            owner = "amkillam";
            repo = "ryzen_smu";
            inherit (ryzenSmu) rev hash;
          };

          patches = (oldAttrs.patches or [ ]) ++ [ ./ryzen-smu-linux-7.2-cpuid.patch ];

          installPhase = ''
            runHook preInstall

            install ryzen_smu.ko -Dm444 -t $out/lib/modules/${config.boot.kernelPackages.kernel.modDirVersion}/kernel/drivers/ryzen_smu

            runHook postInstall
          '';
        }))
      ];

      kernelParams = [
        "preempt=full"
        "mitigations=off"
        "amd_pstate=active"
        "nvme_core.default_ps_max_latency_us=5500"
        "amdgpu.sg_display=0"
        "amdgpu.dcdebugmask=0x40010"
        "transparent_hugepage=always"
        "zswap.enabled=0"
        "nowatchdog"
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

    systemd.services.ryzen-curve-optimizer = {
      description = "Apply Ryzen Curve Optimizer offset";
      wantedBy = [ "multi-user.target" ];
      after = [ "systemd-modules-load.service" ];

      serviceConfig = {
        Type = "oneshot";
        ExecStart = applyRyzenCurveOptimizer;
      };
    };

    powerManagement.resumeCommands = ''
      sleep 2
      ${applyRyzenCurveOptimizer} || true
    '';

    zramSwap = {
      enable = true;
      algorithm = "zstd";
      memoryPercent = 50;
    };
  };
}
