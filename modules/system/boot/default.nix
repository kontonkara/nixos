{ config, lib, pkgs, ... }:

let
  cfg = config.modules.system.boot;

  # Data volume on the MSI alpha chassis (same UUID as in hosts/alpha/hardware.nix).
  dataUuid = "616c4598-89ac-4e5e-b522-4fd98a6bf5ae";
  # Installed by sops-nix (secret name data-luks-key) during prepare-root,
  # before switch-root.
  dataKeyFile = "/run/secrets/data-luks-key";
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
      };
      kernelPackages = pkgs.linuxPackages_latest;
    };

    # Open /data only in the real system, after sops-nix has installed the
    # keyfile. Do not use crypttab: the initrd generator picks that up in
    # parallel with unlocking root and races sops with a plymouth prompt.
    # Keep /data from failing the whole boot if unlock is slow/broken.
    fileSystems."/data".options = [ "nofail" ];

    systemd.services.unlock-data = {
      description = "Unlock LUKS data volume";
      wantedBy = [ "data.mount" ];
      requiredBy = [ "data.mount" ];
      # Must run before local-fs and must not be ordered after basic.target,
      # otherwise data.mount → unlock-data → basic.target forms a cycle.
      before = [
        "data.mount"
        "local-fs-pre.target"
        "umount.target"
      ];
      after = [
        "cryptsetup-pre.target"
        "systemd-udevd.service"
      ];
      wants = [ "cryptsetup-pre.target" ];
      conflicts = [ "umount.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      unitConfig = {
        DefaultDependencies = false;
      };
      script = ''
        if ${pkgs.cryptsetup}/bin/cryptsetup status data >/dev/null 2>&1; then
          exit 0
        fi
        # --allow-discards: the DRAM-less data SSD needs TRIM the most.
        ${pkgs.cryptsetup}/bin/cryptsetup open \
          --allow-discards \
          --key-file=${dataKeyFile} \
          /dev/disk/by-uuid/${dataUuid} \
          data
      '';
    };
  };
}
