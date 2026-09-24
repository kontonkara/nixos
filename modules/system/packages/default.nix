{ config, lib, pkgs, ... }:

let
  cfg = config.modules.system.packages;
in
{
  options = {
    modules = {
      system = {
        packages = {
          enable = lib.mkEnableOption "base system packages";
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    environment = {
      systemPackages = with pkgs; [
        vim
        wget
        pciutils
        usbutils
        nvme-cli
        xwayland-satellite
        sops
        age
        # MSI GPU MUX switcher (efivar + EC; effective after a reboot).
        (callPackage ../../../pkgs/msi-gpu-switcher { })
      ];
    };
  };
}
