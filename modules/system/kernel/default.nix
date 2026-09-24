{ config, lib, pkgs, ... }:

let
  cfg = config.modules.system.kernel;
  ccache = config.modules.system.ccache;

  disable = names: lib.genAttrs (map (name: "CONFIG_${name}") names) (_: "n");

  # Drivers and subsystems for hardware alpha does not have (sysfs: 2x NVMe,
  # RTL8125, AX210, Radeon 610M, RTX 4070, USB webcam; no SATA or SD reader).
  leanKconfig =
    disable [
      # Storage and buses. USB mass storage keeps the generic SCSI core; only
      # the low-level host-adapter drivers go.
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

      # Zen 4 only, with ACPI idle, amd-pstate and the AMD IOMMU. The RAPL
      # modules stay: the AMD powercap driver lives in intel_rapl_common/msr.
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

      # A KVM host, never a guest: KVM_AMD, VFIO, vhost and KVM_HYPERV stay,
      # the guest-side frontends go.
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

      # amdgpu for the iGPU, the out-of-tree driver for the RTX. amdgpu keeps
      # only what Raphael needs.
      "DRM_AMD_ISP"
      "DRM_AMD_SECURE_DISPLAY"
      "DRM_AMDGPU_CIK"
      "DRM_AMDGPU_SI"
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

      # The UVC webcam stack stays; TV, radio and capture cards go.
      "MEDIA_ANALOG_TV_SUPPORT"
      "MEDIA_DIGITAL_TV_SUPPORT"
      "MEDIA_PCI_SUPPORT"
      "MEDIA_PLATFORM_SUPPORT"
      "MEDIA_RADIO_SUPPORT"
      "MEDIA_TEST_SUPPORT"

      # RTL8125 is the only Ethernet controller (Realtek stays).
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

      # AX210 is the only Wi-Fi controller (Intel stays).
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
      # CPU_SUP_* can only be deselected under EXPERT + PROCESSOR_SELECT.
      CONFIG_CPU_SUP_AMD = "y";
      CONFIG_EXPERT = "y";
      CONFIG_PROCESSOR_SELECT = "y";
    };

  # Default initrd modules whose drivers the lean kernel no longer has.
  leanMissingInitrdModules = [
    "ahci"
    "ata_piix"
    "mmc_block"
    "pata_marvell"
    "sata_nv"
    "sata_sis"
    "sata_uli"
    "sata_via"
  ];

  basePackages = pkgs."linuxPackages_cachyos-${cfg.variant}";

  # nyx-cache only has the unmodified kernel. Any Kconfig change means
  # compiling it here, and then ccache is worth it.
  localBuild = cfg.kconfig != { };

  compilerPackages =
    if localBuild && ccache.enable then
      basePackages.cachyOverride {
        stdenv = ccache.wrapStdenv basePackages.kernel.stdenv;
      }
    else
      basePackages;

  kconfigFlag = {
    y = "-e";
    m = "-m";
    n = "-d";
  };
  kconfigArgs = lib.concatLists (
    lib.mapAttrsToList (name: value: [
      kconfigFlag.${value}
      (lib.removePrefix "CONFIG_" name)
    ]) cfg.kconfig
  );

  # Patch the prepared .config itself (not the kernel's configurePhase), so
  # the result can be checked by building kernel.configfile alone, and keep
  # the passthru config the NixOS modules query in sync.
  kernelPackages =
    if localBuild then
      compilerPackages.extend (
        _final: prev: {
          kernel = prev.kernel.override (args: {
            configfile = args.configfile.overrideAttrs (old: {
              postBuild = (old.postBuild or "") + ''
                scripts/config ${lib.escapeShellArgs kconfigArgs}
                make $makeFlags olddefconfig
              '';
            });
            config = args.config // cfg.kconfig;
          });
        }
      )
    else
      compilerPackages;
in
{
  options = {
    modules = {
      system = {
        kernel = {
          enable = lib.mkEnableOption "the cachyos kernel from chaotic-nyx";

          variant = lib.mkOption {
            type = lib.types.enum [
              "lto-znver4"
              "lto"
              "gcc"
            ];
            default = "lto-znver4";
            description = ''
              nyx kernel flavour. lto-znver4: clang thinlto with -march=znver4
              (kernel cached, out-of-tree modules built here); lto: generic
              x86-64 cachyos default; gcc: fallback if clang/lto misbehaves.
            '';
          };

          kconfig = lib.mkOption {
            type = lib.types.attrsOf (
              lib.types.enum [
                "n"
                "m"
                "y"
              ]
            );
            default = { };
            example = {
              CONFIG_DRM_AMDGPU = "y";
            };
            description = "kconfig overrides on top of the cachyos config. Anything here forces a local kernel build.";
          };

          lean = {
            enable = lib.mkEnableOption "dropping drivers for hardware this host lacks (local kernel build)";
          };

          amdgpu = {
            builtIn = {
              enable = lib.mkEnableOption "building amdgpu into the kernel image (local kernel build)";
            };
          };
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    modules = {
      system = {
        kernel = {
          kconfig = lib.mkMerge [
            (lib.mkIf cfg.lean.enable leanKconfig)
            (lib.mkIf cfg.amdgpu.builtIn.enable {
              CONFIG_DRM_AMDGPU = "y";
            })
          ];
        };
      };
    };

    boot = {
      inherit kernelPackages;

      initrd = {
        availableKernelModules = lib.mkIf cfg.lean.enable (
          lib.genAttrs leanMissingInitrdModules (_: lib.mkForce false)
        );
      };
    };
  };
}
