{ pkgs, ... }:

{
  boot = {
    loader = {
      systemd-boot = {
        enable = true;
      };
      efi = {
        canTouchEfiVariables = true;
      };
    };
    initrd = {
      luks = {
        devices = {
          "data" = {
            keyFile = "/etc/secrets/data.key";
          };
        };
      };
      secrets = {
        "/etc/secrets/data.key" = "/etc/secrets/data.key";
      };
    };
    kernelPackages = pkgs.linuxPackages_latest;
  };
}