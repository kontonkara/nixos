{
  config,
  lib,
  pkgs,
  username,
  ...
}:

let
  cfg = config.modules.lab;
in
{
  options = {
    modules = {
      lab = {
        enable = lib.mkEnableOption "virtualisation and homelab tooling";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    virtualisation = {
      libvirtd = {
        enable = true;
        onBoot = "ignore";
        onShutdown = "shutdown";
        shutdownTimeout = 120;
        parallelShutdown = 3;
        allowedBridges = [
          "virbr0"
          "virbr-talos"
        ];
      };

      docker = {
        enable = true;
        autoPrune = {
          enable = true;
          dates = "weekly";
        };
      };
    };

    programs = {
      virt-manager = {
        enable = true;
      };
    };

    users = {
      users = {
        ${username} = {
          extraGroups = [
            "libvirtd"
            "kvm"
            "docker"
          ];
        };
      };
    };

    environment = {
      variables = {
        LIBVIRT_DEFAULT_URI = "qemu:///system";
      };
      systemPackages = with pkgs; [
        talosctl
        kubectl
        kubernetes-helm
        kustomize
        fluxcd
        opentofu
        talhelper
        cilium-cli
        k9s
        kubectx
        stern
        virt-viewer
        dnsutils
        tcpdump
        jq
        yq-go
        shellcheck
        docker-compose
        anki
      ];
    };

    networking = {
      firewall = {
        trustedInterfaces = [ "virbr-talos" ];
      };
    };

    systemd = {
      tmpfiles = {
        rules = [ "d /var/lib/libvirt/images 0711 root root -" ];
      };
    };

    specialisation = {
      lab = {
        configuration = {
          services = {
            sing-box = {
              enable = lib.mkForce false;
            };
          };
          networking = {
            nameservers = lib.mkForce [
              "1.1.1.1"
              "9.9.9.9"
            ];
          };
        };
      };
    };
  };
}
