{ config, lib, username, ... }:

let
  cfg = config.modules.home.ripgrep;
in
{
  options = {
    modules = {
      home = {
        ripgrep = {
          enable = lib.mkEnableOption "ripgrep text search";
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    home-manager = {
      users = {
        ${username} = {
          programs = {
            # No `arguments`: HM would export RIPGREP_CONFIG_PATH to the whole
            # session, and every other rg (Claude Code's Grep, yazi) would
            # inherit --hidden/--smart-case and return different results.
            ripgrep = {
              enable = true;
            };

            # The same defaults for interactive fish only; a function isn't
            # inherited by child processes the way the variable is.
            fish = {
              shellAliases = {
                rg = "rg --smart-case --hidden --glob=!.git/ --glob=!.jj/ --max-columns=150 --max-columns-preview --colors=line:style:bold";
              };
            };
          };
        };
      };
    };
  };
}
