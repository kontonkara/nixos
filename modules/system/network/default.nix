{ config, lib, ... }:

let
  cfg = config.modules.network;
in
{
  options = {
    modules = {
      network = {
        enable = lib.mkEnableOption "NetworkManager";
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
