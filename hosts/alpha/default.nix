{ ... }:

{
  networking = {
    hostName = "alpha";
  };

  modules = {
    home = {
      apps.enable = true;
      git.enable = true;
      fish.enable = true;
      firefox.enable = true;
      kitty.enable = true;
      starship.enable = true;
      yazi.enable = true;
      zoxide.enable = true;
      eza.enable = true;
      bat.enable = true;
      fd.enable = true;
      fzf.enable = true;
      ripgrep.enable = true;
      htop.enable = true;
      btop.enable = true;
      procs.enable = true;
      tealdeer.enable = true;
      k9s.enable = true;
      opencode.enable = true;
      keepassxc.enable = true;
      vesktop.enable = true;
      obsidian.enable = true;
      vscode.enable = true;
      zed.enable = true;
      niri.enable = true;
      noctalia.enable = true;
      xdg.enable = true;
      gtk.enable = true;
      dconf.enable = true;
      nix-index.enable = true;
      direnv.enable = true;
      mangohud.enable = true;
      stylix.enable = true;
    };

    programs = {
      fish.enable = true;
      gamemode.enable = true;
      gamescope.enable = true;
      nh.enable = true;
      steam.enable = true;
      virt-manager.enable = true;
      yandex-browser-corporate.enable = true;
    };

    system = {
      audio.enable = true;
      bluetooth.enable = true;
      boot.enable = true;
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
        };
      };
      services.gvfs.enable = true;
      services.localsearch.enable = true;
      services.ly.enable = true;
      services.power-profiles-daemon.enable = true;
      services.sing-box.enable = true;
      services.sunshine.enable = true;
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
