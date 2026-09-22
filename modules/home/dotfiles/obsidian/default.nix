{ config, lib, username, ... }:

let
  cfg = config.modules.home.obsidian;
in
{
  options = {
    modules = {
      home = {
        obsidian = {
          enable = lib.mkEnableOption "Obsidian";
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    home-manager = {
      users = {
        ${username} = {
          programs = {
            obsidian = {
              enable = true;
            };
          };
        };
      };
    };
  };
}
