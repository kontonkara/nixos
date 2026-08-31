{ config, lib, ... }:

let
  cfg = config.modules.programs.steam;
in
{
  options = {
    modules = {
      programs = {
        steam = {
          enable = lib.mkEnableOption "Steam gaming platform";
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    programs = {
      steam = {
        enable = true;
      };
    };
  };
}
