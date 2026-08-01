{ ... }:

{
  networking = {
    hostName = "alpha";
  };

  imports = [
    ./hardware.nix

    ./../../modules/programs/firefox
    ./../../modules/programs/git

    ./../../modules/services/desktopManager
    ./../../modules/services/displayManager
    ./../../modules/services/xserver

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