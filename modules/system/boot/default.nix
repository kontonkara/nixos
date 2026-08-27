{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.modules.boot;

  disableKernelOptions = names: lib.genAttrs (map (name: "CONFIG_${name}") names) (_name: "n");
  leanKernelConfigOverrides =
    disableKernelOptions [
      # Storage and buses absent from alpha. USB mass storage keeps using the
      # generic SCSI core, while its low-level host-adapter drivers are removed.
      "ACPI_NFIT"
      "ATA"
      "CAN"
      "CXL_BUS"
      "DAX"
      "FIREWIRE"
      "FS_DAX"
      "IIO"
      "INFINIBAND"
      "LIBNVDIMM"
      "MMC"
      "MEMSTICK"
      "MTD"
      "NFC"
      "PCCARD"
      "SCSI_LOWLEVEL"
      "STAGING"
      "TARGET_CORE"
      "USB_GADGET"
      "X86_PMEM_LEGACY"

      # Alpha boots only on Zen 4 and uses ACPI idle, AMD P-State and AMD IOMMU.
      # Keep the generic AMD RAPL modules: despite their names, the active
      # powercap driver is implemented by intel_rapl_common/intel_rapl_msr.
      "AMD_3D_VCACHE"
      "AMD_HSMP"
      "AMD_HSMP_ACPI"
      "AMD_HSMP_PLAT"
      "AMD_PMF"
      "CPU_IDLE_GOV_HALTPOLL"
      "CPU_IDLE_GOV_LADDER"
      "CPU_SUP_CENTAUR"
      "CPU_SUP_HYGON"
      "CPU_SUP_INTEL"
      "CPU_SUP_ZHAOXIN"
      "INTEL_IDLE"
      "INTEL_IOMMU"
      "INTEL_POWERCLAMP"
      "INTEL_RAPL_TPMI"
      "X86_INTEL_PSTATE"
      "X86_PCC_CPUFREQ"
      "X86_PKG_TEMP_THERMAL"
      "X86_POWERNOW_K8"

      # Alpha is a KVM host, not a virtual-machine guest. Keep KVM_AMD, VFIO,
      # VHOST_NET/VSOCK and KVM_HYPERV for guests, but remove guest frontends.
      "BT_VIRTIO"
      "CRYPTO_DEV_VIRTIO"
      "GPIO_VIRTIO"
      "HW_RANDOM_VIRTIO"
      "HYPERVISOR_GUEST"
      "I2C_VIRTIO"
      "KVM_AMD_SEV"
      "KVM_INTEL"
      "KVM_XEN"
      "NET_9P_VIRTIO"
      "REMOTEPROC"
      "RPMSG_VIRTIO"
      "SEV_GUEST"
      "SND_VIRTIO"
      "SPI_VIRTIO"
      "VDPA"
      "VFIO_PCI_IGD"
      "VHOST_VDPA"
      "VIRTIO_BALLOON"
      "VIRTIO_BLK"
      "VIRTIO_CONSOLE"
      "VIRTIO_FS"
      "VIRTIO_IOMMU"
      "VIRTIO_INPUT"
      "VIRTIO_MEM"
      "VIRTIO_MENU"
      "VIRTIO_MMIO"
      "VIRTIO_NET"
      "VIRTIO_RTC"
      "VIRTIO_VDPA"
      "VIRTIO_VFIO_PCI"
      "VIRTIO_VSOCKETS"
      "VMWARE_VMCI"
      "VMWARE_VMCI_VSOCKETS"

      # Alpha uses built-in AMDGPU and the external NVIDIA driver.
      "DRM_AST"
      "DRM_GMA500"
      "DRM_GUD"
      "DRM_I915"
      "DRM_MGAG200"
      "DRM_NOUVEAU"
      "DRM_QXL"
      "DRM_RADEON"
      "DRM_UDL"
      "DRM_VBOXVIDEO"
      "DRM_VIRTIO_GPU"
      "DRM_VKMS"
      "DRM_VMWGFX"
      "DRM_XE"

      # Keep the UVC webcam stack, but remove TV, radio and capture-card stacks.
      "MEDIA_ANALOG_TV_SUPPORT"
      "MEDIA_DIGITAL_TV_SUPPORT"
      "MEDIA_PCI_SUPPORT"
      "MEDIA_PLATFORM_SUPPORT"
      "MEDIA_RADIO_SUPPORT"
      "MEDIA_TEST_SUPPORT"

      # RTL8125B is the only physical Ethernet controller in alpha.
      "NET_VENDOR_3COM"
      "NET_VENDOR_8390"
      "NET_VENDOR_ADAPTEC"
      "NET_VENDOR_ADI"
      "NET_VENDOR_AGERE"
      "NET_VENDOR_ALACRITECH"
      "NET_VENDOR_ALIBABA"
      "NET_VENDOR_AMAZON"
      "NET_VENDOR_AMD"
      "NET_VENDOR_AQUANTIA"
      "NET_VENDOR_ARC"
      "NET_VENDOR_ASIX"
      "NET_VENDOR_ATHEROS"
      "NET_VENDOR_BROADCOM"
      "NET_VENDOR_BROCADE"
      "NET_VENDOR_CADENCE"
      "NET_VENDOR_CAVIUM"
      "NET_VENDOR_CHELSIO"
      "NET_VENDOR_CISCO"
      "NET_VENDOR_CORTINA"
      "NET_VENDOR_DAVICOM"
      "NET_VENDOR_DEC"
      "NET_VENDOR_DLINK"
      "NET_VENDOR_EMULEX"
      "NET_VENDOR_ENGLEDER"
      "NET_VENDOR_EZCHIP"
      "NET_VENDOR_FUNGIBLE"
      "NET_VENDOR_GOOGLE"
      "NET_VENDOR_HISILICON"
      "NET_VENDOR_HUAWEI"
      "NET_VENDOR_I825XX"
      "NET_VENDOR_INTEL"
      "NET_VENDOR_LITEX"
      "NET_VENDOR_MARVELL"
      "NET_VENDOR_MELLANOX"
      "NET_VENDOR_META"
      "NET_VENDOR_MICREL"
      "NET_VENDOR_MICROCHIP"
      "NET_VENDOR_MICROSEMI"
      "NET_VENDOR_MICROSOFT"
      "NET_VENDOR_MUCSE"
      "NET_VENDOR_MYRI"
      "NET_VENDOR_NATSEMI"
      "NET_VENDOR_NETRONOME"
      "NET_VENDOR_NI"
      "NET_VENDOR_NVIDIA"
      "NET_VENDOR_OKI"
      "NET_VENDOR_PENSANDO"
      "NET_VENDOR_QLOGIC"
      "NET_VENDOR_QUALCOMM"
      "NET_VENDOR_RDC"
      "NET_VENDOR_RENESAS"
      "NET_VENDOR_ROCKER"
      "NET_VENDOR_SAMSUNG"
      "NET_VENDOR_SEEQ"
      "NET_VENDOR_SILAN"
      "NET_VENDOR_SIS"
      "NET_VENDOR_SMSC"
      "NET_VENDOR_SOCIONEXT"
      "NET_VENDOR_SOLARFLARE"
      "NET_VENDOR_STMICRO"
      "NET_VENDOR_SUN"
      "NET_VENDOR_SYNOPSYS"
      "NET_VENDOR_TEHUTI"
      "NET_VENDOR_TI"
      "NET_VENDOR_VERTEXCOM"
      "NET_VENDOR_VIA"
      "NET_VENDOR_WANGXUN"
      "NET_VENDOR_WIZNET"
      "NET_VENDOR_XILINX"
      "NET_VENDOR_XIRCOM"

      # AX210 is the only Wi-Fi controller in alpha.
      "WLAN_VENDOR_ADMTEK"
      "WLAN_VENDOR_ATH"
      "WLAN_VENDOR_ATMEL"
      "WLAN_VENDOR_BROADCOM"
      "WLAN_VENDOR_INTERSIL"
      "WLAN_VENDOR_MARVELL"
      "WLAN_VENDOR_MEDIATEK"
      "WLAN_VENDOR_MICROCHIP"
      "WLAN_VENDOR_PURELIFI"
      "WLAN_VENDOR_QUANTENNA"
      "WLAN_VENDOR_RALINK"
      "WLAN_VENDOR_REALTEK"
      "WLAN_VENDOR_RSI"
      "WLAN_VENDOR_SILABS"
      "WLAN_VENDOR_ST"
      "WLAN_VENDOR_TI"
      "WLAN_VENDOR_ZYDAS"
    ]
    // {
      CONFIG_CPU_SUP_AMD = "y";
      CONFIG_EXPERT = "y";
      CONFIG_PROCESSOR_SELECT = "y";
    };

  baseKernelPackages = pkgs.linuxPackages_cachyos-lto-znver4;
  kernelConfigOverrides = cfg.kernel.cachyosConfigOverrides;
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

        kernel = {
          cachyosConfigOverrides = lib.mkOption {
            type = lib.types.attrsOf (
              lib.types.enum [
                "n"
                "m"
                "y"
              ]
            );
            default = { };
            internal = true;
            description = "Kconfig overrides applied to the CachyOS kernel.";
          };

          lean = {
            enable = lib.mkEnableOption "removing kernel drivers and subsystems absent from this host";
          };
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    modules.boot.kernel.cachyosConfigOverrides = lib.mkIf cfg.kernel.lean.enable leanKernelConfigOverrides;

    boot = {
      inherit kernelPackages;

      kernelModules = [
        "msi-ec"
        "ryzen_smu"
        "ntsync"
        "ec_sys"
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

      kernelParams = lib.mkMerge [
        (lib.mkOrder 900 [
          "preempt=full"
          "mitigations=off"
          "amd_pstate=active"
          "amdgpu.sg_display=0"
          "amdgpu.dcdebugmask=0x40010"
        ])
        (lib.mkOrder 920 [
          "nowatchdog"
          "iommu=pt"
          "acpi_backlight=native"
        ])
      ];

      kernel.sysctl = {
        "kernel.nmi_watchdog" = 0;
        "fs.file-max" = 2097152;
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

  };
}
