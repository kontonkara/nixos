{ config, lib, username, ... }:

let
  cfg = config.modules.home.vesktop;
in
{
  options = {
    modules = {
      home = {
        vesktop = {
          enable = lib.mkEnableOption "vesktop discord client";
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    home-manager = {
      users = {
        ${username} = {
          programs = {
            vesktop = {
              enable = true;
            };
          };
        };
      };
    };
  };
}
