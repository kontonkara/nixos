{ config, lib, pkgs, ... }:

let
  cfg = config.modules.system.virtualisation.libvirtd;
in
{
  options = {
    modules = {
      system = {
        virtualisation = {
          libvirtd = {
            enable = lib.mkEnableOption "libvirt qemu/kvm host";
          };
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    virtualisation = {
      libvirtd = {
        enable = true;
        # Only guests marked autostart come up, once libvirtd starts.
        onBoot = "ignore";
        # ACPI shutdown instead of the default managed save (a RAM-sized image
        # per guest), three guests at a time, two minutes each at most.
        onShutdown = "shutdown";
        shutdownTimeout = 120;
        parallelShutdown = 3;
        qemu = {
          # x86_64 guests under KVM only; the full qemu adds ~600 MiB of
          # emulated targets.
          package = pkgs.qemu_kvm;
        };
      };
    };

    # Not at boot: libvirtd.socket starts the daemon at the first virsh or
    # virt-manager connection, and it leaves again after two idle minutes
    # with no guest running. libvirt-guests (the shutdown of guests) comes
    # up with it instead of waking it at boot.
    systemd = {
      services = {
        libvirtd = {
          wantedBy = lib.mkForce [ ];
        };
        libvirt-guests = {
          wantedBy = lib.mkForce [ "libvirtd.service" ];
        };
      };
    };

    environment = {
      variables = {
        # virsh as a user otherwise talks to the empty qemu:///session.
        LIBVIRT_DEFAULT_URI = "qemu:///system";
      };
    };

    networking = {
      firewall = {
        # The Talos lab's libvirt network; its nodes may reach host services.
        trustedInterfaces = [ "virbr-talos" ];
      };
    };
  };
}
