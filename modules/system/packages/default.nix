{ config, lib, pkgs, ... }:

let
  cfg = config.modules.system.packages;

  # 0.8.3 stops focusing override-redirect popups (#494): on 0.8.2 Steam's
  # dropdowns and context menus closed a few ms after they opened. Drop this
  # once nixpkgs has 0.8.3.
  xwayland-satellite = pkgs.xwayland-satellite.overrideAttrs (finalAttrs: _: {
    version = "0.8.3";
    src = pkgs.fetchFromGitHub {
      owner = "Supreeeme";
      repo = "xwayland-satellite";
      tag = "v${finalAttrs.version}";
      hash = "sha256-eFEjCCniMCKeWU0PcZNv+tDYe08SLFPjRplyPY8OFt4=";
    };
    cargoDeps = pkgs.rustPlatform.fetchCargoVendor {
      inherit (finalAttrs) src;
      hash = "sha256-gMGFvnbxM3hD5fmkSimaFd87GEf6BXFe/MGjoS6VNVU=";
    };
  });
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
        # niri runs it from PATH for X11 clients (Steam).
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
        virt-viewer
        dnsutils
        tcpdump
        jq
        yq-go
      ];
    };
  };
}
