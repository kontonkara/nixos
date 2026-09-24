{ config, lib, username, ... }:

let
  cfg = config.modules.home.k9s;
in
{
  options = {
    modules = {
      home = {
        k9s = {
          enable = lib.mkEnableOption "k9s kubernetes tui";
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    home-manager = {
      users = {
        ${username} = {
          programs = {
            k9s = {
              enable = true;
            };
          };
        };
      };
    };
  };
}
