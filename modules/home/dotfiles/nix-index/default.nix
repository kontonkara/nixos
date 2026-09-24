{ config, lib, username, inputs, ... }:

let
  cfg = config.modules.home.nix-index;
in
{
  options = {
    modules = {
      home = {
        nix-index = {
          enable = lib.mkEnableOption "nix-index with a prebuilt database and comma";
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    home-manager = {
      # Imported only here: the module turns programs.nix-index on by default.
      sharedModules = [
        inputs.nix-index-database.homeModules.default
      ];

      users = {
        ${username} = {
          programs = {
            # Weekly prebuilt database instead of indexing the cache locally;
            # also provides fish's command-not-found handler.
            nix-index = {
              enable = true;
            };

            nix-index-database = {
              comma = {
                enable = true;
              };
            };
          };
        };
      };
    };
  };
}
