{ config, lib, username, ... }:

let
  cfg = config.modules.home.zoxide;
in
{
  options = {
    modules = {
      home = {
        zoxide = {
          enable = lib.mkEnableOption "zoxide directory jumping";
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    home-manager = {
      users = {
        ${username} = {
          programs = {
            zoxide = {
              enable = true;
              enableFishIntegration = true;

              # `cd` jumps and `cdi` picks interactively; existing paths still
              # behave like fish's own cd (zoxide wraps a copy of it).
              options = [
                "--cmd"
                "cd"
              ];
            };
          };
        };
      };
    };
  };
}
