{ config, lib, pkgs, ... }:

let
  cfg = config.modules.system.boot;
in
{
  imports = [
    ./plymouth.nix
  ];

  options = {
    modules = {
      system = {
        boot = {
          enable = lib.mkEnableOption "bootloader and luks initrd";

          ecWrite = {
            enable = lib.mkEnableOption "a writable embedded controller over debugfs (ec_sys), which msi-gpu-switcher flips the MUX through";
          };
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    boot = {
      loader = {
        systemd-boot = {
          enable = true;
          # The editor allows init=/bin/sh; each generation's initrd is ~75 MB
          # on a 1 GB ESP.
          editor = false;
          configurationLimit = 10;
        };
        efi = {
          canTouchEfiVariables = true;
        };
        # Enough to pick an older generation, 2 s less than the default.
        timeout = 3;
      };
      # Stock fallback; modules.system.kernel swaps in CachyOS.
      kernelPackages = lib.mkDefault pkgs.linuxPackages_latest;

      # Writable EC over debugfs: msi-gpu-switcher flips the MUX bits there.
      kernelModules = lib.mkIf cfg.ecWrite.enable [ "ec_sys" ];
      extraModprobeConfig = lib.mkIf cfg.ecWrite.enable ''
        options ec_sys write_support=1
      '';

      kernelParams = [
        # Zen 4 pays mostly for SRSO (safe-RET / IBPB on kernel entry);
        # accepted trade-off on a single-user laptop.
        "mitigations=off"
        # Identity-map DMA for host devices (the kernel default is translated);
        # weaker protection against DMA from external devices.
        "iommu=pt"
        # Frees the PMU counter the NMI hard-lockup detector pins; the
        # soft-lockup detector stays for diagnosing hangs.
        "nmi_watchdog=0"
        # CachyOS turns EFI pstore off; keep oops/panic logs across a reset
        # (systemd-pstore archives them to /var/lib/systemd/pstore).
        "efi_pstore.pstore_disable=0"
        # The clocksource watchdog once marked the (invariant) Zen 4 TSC
        # unstable right after an s2idle resume, over a 0.2 ms HPET interval,
        # which left the whole system on slow HPET reads until a reboot. The
        # boot-time TSC sync check stays.
        "tsc=nowatchdog"
      ];

      kernel = {
        sysctl = {
          # SysRq sync (16) + remount read-only (32) + reboot (128): Alt+SysRq
          # S, U, B instead of the power button when the desktop hangs.
          "kernel.sysrq" = 176;
        };
      };
    };
  };
}
