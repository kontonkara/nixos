{ pkgs, ... }:

{
  boot = {
    kernelPackages = pkgs.linuxPackages_latest;
    loader = {
      systemd-boot = {
        enable = true;
        configurationLimit = 7;
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
}