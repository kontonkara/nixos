{ config, lib, ... }:

let
  cfg = config.modules.programs.niri;
in
{
  options = {
    modules = {
      programs = {
        niri = {
          enable = lib.mkEnableOption "niri wayland compositor";
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    programs = {
      niri = {
        enable = true;
      };
    };
  };
}
