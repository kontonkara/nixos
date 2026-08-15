{ config, lib, ... }:

let
  cfg = config.modules.desktop.xserver;
in
{
  options.modules.desktop.xserver.enable = lib.mkEnableOption "X server compatibility support";

  config = lib.mkIf cfg.enable {
    services = {
      xserver = {
        enable = true;
        xkb = {
          layout = "us,ru";
          options = "grp:alt_shift_toggle";
        };
        videoDrivers = [
          "nvidia"
        ];
      };
    };
  };
}
