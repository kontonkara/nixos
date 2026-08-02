{ pkgs, ... }:

{
  environment = {
    systemPackages = with pkgs; [
      mcontrolcenter
      vim
      wget
      sops
      age
    ];
  };
}
