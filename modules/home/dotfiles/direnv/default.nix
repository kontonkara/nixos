{ config, lib, username, ... }:

let
  cfg = config.modules.home.direnv;
in
{
  options = {
    modules = {
      home = {
        direnv = {
          enable = lib.mkEnableOption "direnv with nix-direnv";
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    home-manager = {
      users = {
        ${username} = {
          programs = {
            direnv = {
              enable = true;
              silent = true;

              nix-direnv = {
                enable = true;
              };

              config = {
                global = {
                  strict_env = true;
                  warn_timeout = "1m";
                };
              };
            };
          };
        };
      };
    };
  };
}
