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
            enable = lib.mkEnableOption "homelab clis (talos, kubernetes, flux)";
          };

          msiGpuSwitcher = {
            enable = lib.mkEnableOption "the MSI GPU MUX switcher (efivar + EC; effective after a reboot)";
          };
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.msiGpuSwitcher.enable -> config.modules.system.boot.ecWrite.enable;
        message = "modules.system.packages.msiGpuSwitcher needs modules.system.boot.ecWrite (it writes the MUX bits through ec_sys)";
      }
    ];

    environment = {
      systemPackages = with pkgs; [
        vim
        wget
        pciutils
        usbutils
        nvme-cli
        # niri runs it from PATH for X11 clients (Steam).
        xwayland-satellite
        sops
        age
      ]
      ++ lib.optional cfg.msiGpuSwitcher.enable (callPackage ../../../pkgs/msi-gpu-switcher { })
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
        virt-viewer
        dnsutils
        tcpdump
        jq
        yq-go
      ];
    };
  };
}
