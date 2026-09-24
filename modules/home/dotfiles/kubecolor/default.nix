{ config, lib, username, ... }:

let
  cfg = config.modules.home.kubecolor;
in
{
  options = {
    modules = {
      home = {
        kubecolor = {
          enable = lib.mkEnableOption "kubecolor kubectl output colorizer";
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    home-manager = {
      users = {
        ${username} = {
          programs = {
            # Colours come from stylix. Not enableAlias: with fish's
            # preferAbbrs Home Manager turns it into an abbreviation that
            # expands to kubecolor's store path.
            kubecolor = {
              enable = true;
            };

            # Interactive fish only; scripts keep the plain kubectl. kubectl's
            # own completions still work, kubecolor passes `__complete` through.
            fish = {
              shellAliases = {
                kubectl = "kubecolor";
              };
            };
          };
        };
      };
    };
  };
}
