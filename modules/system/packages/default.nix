{ pkgs, ... }:

{
  environment = {
    systemPackages = with pkgs; [
      vim
      wget
      sops
      age
    ];
  };
}