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

          lab = {
            enable = lib.mkEnableOption "homelab clis (talos, kubernetes, flux, opentofu)";
          };
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
      ]
      ++ lib.optionals cfg.lab.enable [
        talosctl
        talhelper
        kubectl
        kubectx
        kubernetes-helm
        kustomize
        fluxcd
        cilium-cli
        stern
        opentofu
        virt-viewer
        dnsutils
        tcpdump
        jq
        yq-go
        shellcheck
      ];
    };
  };
}
