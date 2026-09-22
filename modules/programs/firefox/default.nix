{ config, lib, ... }:

let
  cfg = config.modules.programs.firefox;
in
{
  options = {
    modules = {
      programs = {
        firefox = {
          enable = lib.mkEnableOption "Firefox";
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    programs = {
      firefox = {
        enable = true;
      };
    };
  };
}
