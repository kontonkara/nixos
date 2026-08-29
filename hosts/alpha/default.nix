{ lib, pkgs, ... }:

{
  networking.hostName = "alpha";

  modules = {
    home = {
      apps.enable = true;
      cli.enable = true;
      fish.enable = true;
      kdeColorScheme.enable = true;
      nixTools.enable = true;
      obsidian.enable = true;
      stylix.enable = true;
      vesktop.enable = true;
      vscode.enable = true;
      xdg.enable = true;
    };

    programs = {
      firefox.enable = true;
      git.enable = true;
      steam.enable = true;
      yandex-browser-corporate.enable = true;
    };

    desktop = {
      plasma.enable = true;
      sddm.enable = true;
      xserver.enable = true;
    };

    services = {
      sing-box.enable = true;
      sunshine.enable = true;
      udev.enable = true;
    };

    graphics = {
      amd = {
        enable = true;

        kernel = {
          builtIn.enable = true;
          removeUnsupportedRgba8888.enable = true;
          preserveRaphaelSmuDpmDuringS0ix.enable = true;
          trimUnsupportedHardware.enable = true;
        };

        mesa = {
          cpuArch = "znver4";
          optimizationLevel = 3;
          disableAssertions = true;
        };
      };
      nvidia = {
        enable = true;
        dynamicBoost.enable = true;
        runtimeD3NotifyFix.enable = true;
      };
    };

    audio.enable = true;
    bluetooth.enable = true;
    boot = {
      enable = true;
      kernel.lean.enable = true;
    };
    ccache.enable = true;
    core.enable = true;
    environment.enable = true;
    lab.enable = true;
    locale.enable = true;
    memory.enable = true;
    network = {
      enable = true;
      wifi.lowLatency.enable = true;
    };
    packages.enable = true;
    power = {
      enable = true;
      display = {
        enable = true;
        connector = "eDP-1";
        acAbmLevel = 0;
        batteryAbmLevel = 4;
      };
      msiEc = {
        enable = true;
        rearmHighPerformance.enable = true;
      };
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
