{ config, lib, username, ... }:

let
  cfg = config.modules.home.fzf;
in
{
  options = {
    modules = {
      home = {
        fzf = {
          enable = lib.mkEnableOption "fzf defaults";
        };
      };
    };
  };

  # Key bindings come from fzf.fish (fish module), so fzf's own widget
  # options (Ctrl+T, Alt+C, Ctrl+R) would be dead; fzf.fish does read
  # FZF_DEFAULT_OPTS.
  config = lib.mkIf cfg.enable {
    home-manager = {
      users = {
        ${username} = {
          programs = {
            fzf = {
              enable = true;
              defaultCommand = "fd --type f";

              defaultOptions = [
                # Ctrl+/ hides the preview in narrow windows; Alt+/ still
                # toggles line wrap.
                "--bind=ctrl-d:preview-page-down,ctrl-u:preview-page-up,ctrl-/:toggle-preview"
                "--border=rounded"
                "--cycle"
                "--height=45%"
                "--info=inline"
                "--layout=reverse"
                "--marker=+"
                # Quoted: fzf splits FZF_DEFAULT_OPTS like a shell and silently
                # drops everything after a bare `>` or `|`, stylix's colors too.
                "--pointer='>'"
                "--preview-window=right:60%:wrap"
                "--scrollbar='|'"
              ];
            };
          };
        };
      };
    };
  };
}
