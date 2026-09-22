{ pkgs, ... }:

{
  environment = {
    systemPackages = with pkgs; [
      vim
      wget
      alacritty
      fuzzel
      xwayland-satellite
      vscode
    ];
  };
}