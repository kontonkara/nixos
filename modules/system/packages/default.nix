{ config, lib, pkgs, ... }:

let
  cfg = config.modules.system.packages;
in
{
  options = {
    modules = {
      system = {
        packages = {
          enable = lib.mkEnableOption "base system packages";
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    environment = {
      systemPackages = with pkgs; [
        vim
        wget
        alacritty
        fuzzel
        xwayland-satellite
        vscode
        sops
        age
      ];
    };
  };
}
