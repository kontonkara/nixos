{ config, lib, ... }:

let
  cfg = config.modules.desktop.sddm;
in
{
  options.modules.desktop.sddm.enable = lib.mkEnableOption "SDDM display manager";

  config = lib.mkIf cfg.enable {
    services = {
      displayManager = {
        sddm = {
          enable = true;
          wayland = {
            enable = true;
          };
        };
      };
    };
  };
}
