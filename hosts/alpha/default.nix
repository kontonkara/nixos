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
      amd.enable = true;
      nvidia.enable = true;
    };

    audio.enable = true;
    bluetooth.enable = true;
    boot.enable = true;
    core.enable = true;
    environment.enable = true;
    lab.enable = true;
    locale.enable = true;
    network.enable = true;
    packages.enable = true;
    power = {
      enable = true;
      msiEc.enable = true;
    };
    users.kontonkara.enable = true;
  };
}
