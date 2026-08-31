{
  config,
  lib,
  username,
  ...
}:

let
  cfg = config.modules.home.fzf;
in
{
  options.modules.home.fzf.enable = lib.mkEnableOption "fzf fuzzy-finder configuration";

  config = lib.mkIf cfg.enable {
    home-manager = {
      users = {
        ${username} = {
          programs = {
            fzf = {
              enable = true;
              enableFishIntegration = true;

              changeDirWidget = {
                command = "fd --type d";

                options = [
                  "--preview=eza --tree --level=2 --color=always --icons=auto {}"
                ];
              };

              defaultCommand = "fd --type f";

              defaultOptions = [
                "--bind=ctrl-d:preview-page-down,ctrl-u:preview-page-up"
                "--border=rounded"
                "--cycle"
                "--height=45%"
                "--info=inline"
                "--layout=reverse"
                "--marker=+"
                "--pointer=>"
                "--preview-window=right:60%:wrap"
                "--prompt=> "
                "--scrollbar=|"
              ];

              fileWidget = {
                command = "fd --type f";

                options = [
                  "--preview=bat --color=always --style=numbers --line-range=:200 {}"
                ];
              };

              historyWidget.options = [
                "--exact"
                "--sort"
              ];
            };
          };
        };
      };
    };
  };
}
