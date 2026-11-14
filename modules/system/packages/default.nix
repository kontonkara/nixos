{ config, lib, pkgs, ... }:

let
  cfg = config.modules.system.packages;

  # 0.8.3 sends xdg_output's logical size before the new wl_output mode, so
  # after an output mode change X11 keeps the size of the mode before it (Wine
  # saw 2560x1440 under the stretched 1440x1080, then 1440x1080 back on the
  # native mode). Both fixes are upstream after 0.8.3; drop this with the next
  # release.
  xwayland-satellite = pkgs.xwayland-satellite.overrideAttrs (old: {
    patches = (old.patches or [ ]) ++ [
      (pkgs.fetchpatch {
        name = "send-xdg-logical-size-after-wl-output-mode.patch";
        url = "https://github.com/Supreeeme/xwayland-satellite/commit/1442ccfd1dc7b93c7de44e10204a7e6d7298a709.patch";
        hash = "sha256-n4o6hRiybZAUxyuWnz2G3OCgr72T1kIjXccJpfHNgHs=";
      })
      (pkgs.fetchpatch {
        name = "send-xdg-output-done-along-wl-output-done.patch";
        url = "https://github.com/Supreeeme/xwayland-satellite/commit/f4b0a97b732cd530d126de2c3f35c0849b3b800d.patch";
        hash = "sha256-77KwGZN2oGWYR5UkKRtX+ROmP03u8RPlYZpTfUTCuc8=";
      })
    ];
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
