{ ... }:

{
  networking.hostName = "alpha";

  modules = {
    home = {
      apps.enable = true;
      fish.enable = true;
      obsidian.enable = true;
      vesktop.enable = true;
      vscode.enable = true;
    };

    programs = {
      firefox.enable = true;
      git.enable = true;
    };

    desktop = {
      plasma.enable = true;
      sddm.enable = true;
      xserver.enable = true;
    };

    services = {
      sing-box.enable = true;
      sunshine.enable = true;
    };

    graphics = {
      amd = {
        enable = true;

        kernel = {
          removeUnsupportedRgba8888.enable = true;
        };

        mesa = {
          cpuArch = "znver4";
          optimizationLevel = 3;
          disableAssertions = true;
        };
      };
      nvidia.enable = true;
    };

    audio.enable = true;
    bluetooth.enable = true;
    boot.enable = true;
    ccache.enable = true;
    core.enable = true;
    environment.enable = true;
    lab.enable = true;
    locale.enable = true;
    network = {
      enable = true;
      wifi.lowLatency.enable = true;
    };
    packages.enable = true;
    power = {
      enable = true;
      msiEc.enable = true;
    };
    scx.enable = true;
    storage = {
      enable = true;

      btrfs = {
        mountPoints = [
          "/"
          "/data"
          "/home"
          "/nix"
          "/var/log"
        ];

        scrub.fileSystems = [
          "/"
          "/data"
        ];
      };

      luks = {
        allowDiscards = true;
        devices = [
          "data"
          "system"
        ];
      };
    };
    users.kontonkara.enable = true;
  };
}
