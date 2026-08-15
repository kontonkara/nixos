{
  config,
  lib,
  username,
  pkgs,
  ...
}:

let
  cfg = config.modules.home.fish;
in
{
  options.modules.home.fish.enable = lib.mkEnableOption "Fish home configuration";

  config = lib.mkIf cfg.enable {
    home-manager = {
      users = {
        ${username} = {
          programs = {
            fish = {
              enable = true;
              generateCompletions = true;
              preferAbbrs = true;

              interactiveShellInit = ''
                set fish_greeting
                set -gx LESS "-FRX"
              '';

              plugins = [
                {
                  name = "autopair";
                  src = pkgs.fishPlugins.autopair.src;
                }
                {
                  name = "bass";
                  src = pkgs.fishPlugins.bass.src;
                }
                {
                  name = "done";
                  src = pkgs.fishPlugins.done.src;
                }
                {
                  name = "fzf-fish";
                  src = pkgs.fishPlugins.fzf-fish.src;
                }
                {
                  name = "sponge";
                  src = pkgs.fishPlugins.sponge.src;
                }
              ];
            };
          };
        };
      };
    };
  };
}
