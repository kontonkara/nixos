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

    ./../../modules/programs/firefox
    ./../../modules/programs/fish
    ./../../modules/programs/git
    ./../../modules/programs/niri
    ./../../modules/programs/yandex-browser-corporate

    ./../../modules/system/audio
    ./../../modules/system/boot
    ./../../modules/system/core
    ./../../modules/system/locale
    ./../../modules/system/network
    ./../../modules/system/packages
    ./../../modules/system/secrets

    ./../../users/kontonkara
  ];
}