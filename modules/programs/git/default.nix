{ config, lib, ... }:

let
  cfg = config.modules.programs.git;
in
{
  options = {
    modules = {
      programs = {
        git = {
          enable = lib.mkEnableOption "Git";
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    programs = {
      git = {
        enable = true;
      };
    };
  };
}
