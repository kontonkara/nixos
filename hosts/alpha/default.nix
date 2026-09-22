{ ... }:

{
  networking = {
    hostName = "alpha";
  };

  imports = [
    ./hardware.nix

    ./../../modules/programs/firefox
    ./../../modules/programs/git
    ./../../modules/programs/niri

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