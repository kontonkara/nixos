{ pkgs, ... }:

{
  environment = {
    systemPackages = with pkgs; [
      mcontrolcenter
      binutils
      pciutils
      usbutils
      nvme-cli
      ryzenadj
      wget
      sops
      age
    ];
  };
}
