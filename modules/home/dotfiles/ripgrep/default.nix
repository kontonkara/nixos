{
  config,
  lib,
  username,
  ...
}:

let
  cfg = config.modules.home.ripgrep;
in
{
  options.modules.home.ripgrep.enable = lib.mkEnableOption "ripgrep text-search configuration";

  config = lib.mkIf cfg.enable {
    home-manager = {
      users = {
        ${username} = {
          programs = {
            ripgrep = {
              enable = true;

              arguments = [
                "--colors=line:style:bold"
                "--glob=!.direnv/"
                "--glob=!.git/"
                "--glob=!.jj/"
                "--glob=!.next/"
                "--glob=!.nuxt/"
                "--glob=!.venv/"
                "--glob=!build/"
                "--glob=!coverage/"
                "--glob=!dist/"
                "--glob=!node_modules/"
                "--glob=!result"
                "--glob=!result-*"
                "--glob=!target/"
                "--hidden"
                "--max-columns-preview"
                "--max-columns=150"
                "--smart-case"
              ];
            };
          };
        };
      };
    };
  };
}
