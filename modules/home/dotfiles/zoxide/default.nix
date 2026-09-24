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
          home = {
            sessionVariables = {
              # Keeps store paths visited while debugging builds out of the
              # database; replaces the default, which excludes $HOME only.
              _ZO_EXCLUDE_DIRS = "$HOME:/nix/store/*";
            };
          };

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
