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
      obsidian.enable = true;
      vscode.enable = true;
      niri.enable = true;
      xdg.enable = true;
      gtk.enable = true;
      dconf.enable = true;
    };

    programs = {
      fish.enable = true;
      yandex-browser-corporate.enable = true;
    };

    system = {
      audio.enable = true;
      bluetooth.enable = true;
      boot.enable = true;
      ccache.enable = true;
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
      services.gvfs.enable = true;
      services.localsearch.enable = true;
      services.ly.enable = true;
      services.sunshine.enable = true;
      services.tinysparql.enable = true;
      services.udisks2.enable = true;
      services.upower.enable = true;
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
