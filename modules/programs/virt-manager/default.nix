{ config, lib, ... }:

let
  cfg = config.modules.programs.virt-manager;
in
{
  options = {
    modules = {
      programs = {
        virt-manager = {
          enable = lib.mkEnableOption "virt-manager";
        };
      };
    };
  };

  # The NixOS module also seeds dconf to autoconnect to qemu:///system.
  config = lib.mkIf cfg.enable {
    programs = {
      virt-manager = {
        enable = true;
      };
    };
  };
}
