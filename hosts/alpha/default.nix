{ ... }:

{
  networking = {
    hostName = "alpha";
  };

  imports = [
    ./hardware.nix

    ./../../modules/home/apps
    ./../../modules/home/dotfiles/obsidian
    ./../../modules/home/dotfiles/vscode

    ./../../modules/lab

    ./../../modules/programs/firefox
    ./../../modules/programs/git

    ./../../modules/services/desktopManager
    ./../../modules/services/displayManager
    ./../../modules/services/sing-box
    ./../../modules/services/xserver

    ./../../modules/system/audio
    ./../../modules/system/bluetooth
    ./../../modules/system/boot
    ./../../modules/system/core
    ./../../modules/system/environment
    ./../../modules/system/locale
    ./../../modules/system/network
    ./../../modules/system/packages
    ./../../modules/system/secrets

    ./../../users/kontonkara
  ];
}
