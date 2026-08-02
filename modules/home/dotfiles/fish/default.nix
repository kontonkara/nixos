{ username, pkgs, ... }:

{
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
}
