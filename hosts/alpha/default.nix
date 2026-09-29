{ ... }:

{
  networking = {
    hostName = "alpha";
  };

  # The release alpha was installed with; never bump it.
  system = {
    stateVersion = "26.05";
  };

  # One build at a time on 24 of the 32 threads: long all-core loads have
  # ended in a machine-check reset on this CPU (BIOS Curve Optimizer).
  nix = {
    settings = {
      max-jobs = 1;
      cores = 24;
    };
  };

  modules = {
    home = {
      apps.enable = true;
      git.enable = true;
      ssh.enable = true;
      fish.enable = true;
      firefox.enable = true;
      kitty.enable = true;
      starship.enable = true;
      yazi.enable = true;
      nautilus.enable = true;
      zoxide.enable = true;
      eza.enable = true;
      vivid.enable = true;
      bat.enable = true;
      fd.enable = true;
      fzf.enable = true;
      ripgrep.enable = true;
      htop.enable = true;
      procs.enable = true;
      tealdeer.enable = true;
      k9s.enable = true;
      opencode.enable = true;
      mimo-code.enable = true;
      keepassxc.enable = true;
      telegram-desktop.enable = true;
      vesktop.enable = true;
      spotify.enable = true;
      obsidian.enable = true;
      zed.enable = true;
      anki.enable = true;
      prismlauncher.enable = true;
      niri.enable = true;
      noctalia.enable = true;
      xdg.enable = true;
      gtk.enable = true;
      dconf.enable = true;
      nix-index.enable = true;
      direnv.enable = true;
      kubecolor.enable = true;
      opentofu.enable = true;
      shellcheck.enable = true;
      mangohud.enable = true;
      obs-studio.enable = true;
      stylix.enable = true;
    };

    programs = {
      fish.enable = true;
      gamemode.enable = true;
      gamescope.enable = true;
      mcontrolcenter.enable = true;
      nh.enable = true;
      nix-ld.enable = true;
      steam.enable = true;
      virt-manager.enable = true;
      yandex-browser-corporate.enable = true;
    };

    system = {
      audio = {
        enable = true;
        speakers = {
          enable = true;
          card = "alsa_card.pci-0000_06_00.6";
          sink = "alsa_output.pci-0000_06_00.6.analog-stereo";
          # MSI's own tuning of these speakers: the FIR Nahimic runs on them
          # on Windows (Devices/146213ED_InternalSpeakers.nsx in its
          # NH3ProductSettings0.cab), 2048 taps per channel at 48 kHz.
          impulseResponse = ./speakers-fir.wav;
        };
      };
      # /home to the second NVMe (data.nix).
      backup = {
        enable = true;
        device = "/dev/mapper/system";
        subvolumes = [ "@home" ];
        target = "/data/backups/alpha";
        # Caches and games that come back by themselves; Steam's compatdata
        # (Proton saves) stays in the snapshots.
        homeSubvolumes = [
          ".cache"
          ".local/share/Steam/steamapps/common"
          ".local/share/Steam/steamapps/shadercache"
        ];
      };
      bluetooth.enable = true;
      boot = {
        enable = true;
        # For msi-gpu-switcher below: the MUX bits are in the EC.
        ecWrite.enable = true;
      };
      ccache.enable = true;
      core.enable = true;
      environment = {
        enable = true;
        gaming.enable = true;
      };
      graphics = {
        amd = {
          enable = true;
          mesa = {
            cpuArch = "znver4";
            optimizationLevel = 3;
            disableAssertions = true;
          };
        };
        nvidia = {
          enable = true;
          dynamicBoost.enable = true;
          # Radeon 610M iGPU / RTX 4070 Laptop on this MSI chassis.
          prime = {
            amdgpuBusId = "PCI:6:0:0";
            nvidiaBusId = "PCI:1:0:0";
          };
        };
      };
      services.gvfs.enable = true;
      services.localsearch.enable = true;
      services.ly.enable = true;
      services.power-profiles-daemon.enable = true;
      services.smartd.enable = true;
      services.sing-box.enable = true;
      services.sunshine.enable = true;
      services.syncthing.enable = true;
      services.tinysparql.enable = true;
      services.udev.enable = true;
      services.udisks2.enable = true;
      services.upower.enable = true;
      kernel = {
        enable = true;
        # Either one means a local clang thinlto kernel build instead of
        # nyx-cache.
        lean.enable = true;
        amdgpu.builtIn.enable = true;
      };
      locale.enable = true;
      memory.enable = true;
      msi-ec = {
        enable = true;
        chargeThreshold = 80;
        modes = {
          enable = true;
          # rearmTurbo.enable = true;
        };
      };
      network = {
        enable = true;
        iwlwifi.enable = true;
      };
      packages = {
        enable = true;
        lab.enable = true;
        msiGpuSwitcher.enable = true;
      };
      scx.enable = true;
      secrets.enable = true;
      storage = {
        enable = true;
        btrfs = {
          mountPoints = [
            "/"
            "/home"
            "/nix"
            "/var/log"
            "/data"
          ];
          scrub.fileSystems = [
            "/"
            "/data"
          ];
        };
        luks.discardDevices = [ "system" ];
      };
      virtualisation = {
        docker.enable = true;
        libvirtd.enable = true;
      };
    };

    users = {
      kontonkara.enable = true;
    };
  };
}
