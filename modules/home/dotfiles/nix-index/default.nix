{ config, lib, username, inputs, ... }:

let
  cfg = config.modules.home.nix-index;

  nix-locate = "${config.home-manager.users.${username}.programs.nix-index.package}/bin/nix-locate";
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
            # Weekly prebuilt database instead of indexing the cache locally.
            # Its own command-not-found script still suggests nix-env -iA; the
            # fish handler below offers comma and nix shell instead.
            nix-index = {
              enable = true;
              enableFishIntegration = false;
            };

            fish = {
              functions = {
                __fish_command_not_found_handler = {
                  onEvent = "fish_command_not_found";
                  body = ''
                    set -l cmd $argv[1]
                    set -l attrs (${nix-locate} --minimal --no-group --type x --type s --whole-name --at-root "/bin/$cmd")
                    if test (count $attrs) -eq 0
                        printf 'fish: Unknown command: %s\n' $cmd >&2
                        return 127
                    end
                    set attrs (string replace -r '\.out$' "" -- $attrs)
                    printf '%s is not installed; nixpkgs has it in %s\n' $cmd (string join ', ' -- $attrs) >&2
                    printf '  run it once:  , %s\n' (string join ' ' -- (string escape -- $argv)) >&2
                    printf '  or a shell:   nix shell nixpkgs#%s\n' $attrs[1] >&2
                    return 127
                  '';
                };
              };
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
