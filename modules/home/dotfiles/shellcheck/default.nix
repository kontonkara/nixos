{ config, lib, pkgs, username, ... }:

let
  cfg = config.modules.home.shellcheck;
in
{
  options = {
    modules = {
      home = {
        shellcheck = {
          enable = lib.mkEnableOption "shellcheck shell script linter";
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    home-manager = {
      users = {
        ${username} = {
          home = {
            packages = [
              pkgs.shellcheck
            ];
          };

          # The fallback after every parent dir's .shellcheckrc; the first
          # file found wins whole, so a project's rc replaces this one.
          xdg = {
            configFile = {
              "shellcheckrc" = {
                # Follow `source`d files like -x (a script can't enable that
                # itself), resolving relative paths from the script's dir
                # rather than the cwd.
                text = ''
                  external-sources=true
                  source-path=SCRIPTDIR
                '';
              };
            };
          };
        };
      };
    };
  };
}
