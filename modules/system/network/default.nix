{ config, lib, ... }:

let
  cfg = config.modules.system.network;
in
{
  options = {
    modules = {
      system = {
        network = {
          enable = lib.mkEnableOption "networkmanager";
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    networking = {
      networkmanager = {
        enable = true;
      };
    };
  };
}
