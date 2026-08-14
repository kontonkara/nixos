{ ... }:

{
  networking = {
    hostName = "alpha";
  };

  imports = [
    ./hardware.nix

    ./../../modules/home/apps
    ./../../modules/home/dotfiles/fish
    ./../../modules/home/dotfiles/obsidian
    ./../../modules/home/dotfiles/vesktop
    ./../../modules/home/dotfiles/vscode

    ./../../modules/lab

    ./../../modules/programs/firefox
    ./../../modules/programs/git
    ./../../modules/programs/yandex-browser-corporate

    ./../../modules/services/desktopManager
    ./../../modules/services/displayManager
    ./../../modules/services/sing-box
    ./../../modules/services/sunshine
    ./../../modules/services/xserver

    ./../../modules/system/audio
    ./../../modules/system/bluetooth
    ./../../modules/system/boot
    ./../../modules/system/core
    ./../../modules/system/environment
    ./../../modules/system/graphics/amd
    ./../../modules/system/graphics/nvidia
    ./../../modules/system/locale
    ./../../modules/system/network
    ./../../modules/system/packages
    ./../../modules/system/secrets

    ./../../pkgs/yandex-browser-corporate

    ./../../users/kontonkara
  ];
}
