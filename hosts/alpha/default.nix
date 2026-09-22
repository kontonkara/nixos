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
      starship.enable = true;
      obsidian.enable = true;
      vscode.enable = true;
    };

    programs = {
      firefox.enable = true;
      fish.enable = true;
      niri.enable = true;
      yandex-browser-corporate.enable = true;
    };

    system = {
      audio.enable = true;
      boot.enable = true;
      core.enable = true;
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
      locale.enable = true;
      network.enable = true;
      packages.enable = true;
      secrets.enable = true;
    };

    users = {
      kontonkara.enable = true;
    };
  };
}
