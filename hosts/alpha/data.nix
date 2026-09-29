# The second NVMe (/data in hardware.nix): LUKS with a keyfile from sops.
{ pkgs, ... }:

let
  dataUuid = "616c4598-89ac-4e5e-b522-4fd98a6bf5ae";
  # Installed by sops-nix during prepare-root, before switch-root.
  dataKeyFile = "/run/secrets/data-luks-key";
in
{
  sops = {
    secrets = {
      # LUKS keyfile for /data; consumed by unlock-data.service.
      "data-luks-key" = {
        format = "binary";
        sopsFile = ../../secrets/data-luks-key;
        mode = "0400";
      };
    };
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
    # Beside the boot rather than before local-fs: /data is nofail, so
    # nothing at boot waits for it (btrbk checks the mount itself), and the
    # login screen no longer waits the ~1.6 s its keyslot takes to open.
    # DefaultDependencies = false keeps it off basic.target, which would
    # close a data.mount → unlock-data → basic.target cycle.
    before = [
      "data.mount"
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
}
