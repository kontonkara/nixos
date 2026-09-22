{ config, lib, ... }:

let
  cfg = config.modules.programs.fish;
in
{
  options = {
    modules = {
      programs = {
        fish = {
          enable = lib.mkEnableOption "system-wide fish shell";
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    programs = {
      fish = {
        enable = true;
        generateCompletions = true;
      };
    };
  };
}
