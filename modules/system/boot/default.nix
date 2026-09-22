{ config, lib, pkgs, ... }:

let
  cfg = config.modules.system.boot;
in
{
  options = {
    modules = {
      system = {
        boot = {
          enable = lib.mkEnableOption "bootloader and LUKS initrd";
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
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
  };
}
