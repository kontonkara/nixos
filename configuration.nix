# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ config, lib, pkgs, ... }:

{
  imports =
    [
      ./hardware.nix
    ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.initrd.luks.devices."data".keyFile = "/etc/secrets/data.key";
  boot.initrd.secrets."/etc/secrets/data.key" = "/etc/secrets/data.key";
  boot.kernelPackages = pkgs.linuxPackages_latest;

  networking.hostName = "alpha";

  networking.networkmanager.enable = true;

  time.timeZone = "Europe/Minsk";

  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    useXkbConfig = true;
  };

  services.pipewire = {
    enable = true;
    pulse.enable = true;
  };

  services.libinput.enable = true;

  users.users.kontonkara = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    packages = with pkgs; [
      tree
      telegram-desktop
      keepassxc
    ];
  };

  nixpkgs = {
    config = {
      allowUnfree = true;
    };
  };

  programs.firefox.enable = true;
  programs.git.enable = true;
  programs.niri.enable = true;

  environment.systemPackages = with pkgs; [
    vim
    wget
    alacritty
    fuzzel
    xwayland-satellite
    vscode
  ];

  system.stateVersion = "26.05";
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
}

