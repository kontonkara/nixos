{
  config,
  lib,
  username,
  ...
}:

let
  cfg = config.modules.programs.git;
in
{
  options = {
    modules = {
      programs = {
        git = {
          enable = lib.mkEnableOption "Git version-control tooling";
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    programs = {
      git = {
        enable = true;
      };
    };

    home-manager = {
      users = {
        ${username} = {
          programs = {
            delta = {
              enable = true;
              enableGitIntegration = true;
              options = {
                features = "decorations";
                line-numbers = true;
                navigate = true;
                side-by-side = false;
              };
            };

            git = {
              enable = true;
              lfs.enable = true;

              ignores = [
                ".DS_Store"
                "Thumbs.db"
                ".direnv"
                "node_modules"
                "*.log"
              ];

              settings = {
                alias = {
                  amend = "commit --amend --no-edit";
                  br = "branch";
                  co = "checkout";
                  last = "log -1 HEAD";
                  lg = "log --color --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit";
                  root = "rev-parse --show-toplevel";
                  st = "status -sb";
                  unstage = "reset HEAD --";
                };
                color.ui = true;
                core.whitespace = "fix,space-before-tab,tab-in-indent,trailing-space";
                diff.algorithm = "histogram";
                init.defaultBranch = "main";
                maintenance.auto = true;
                merge.conflictStyle = "zdiff3";
                pull.rebase = true;
                push.autoSetupRemote = true;
                rerere.enabled = true;
              };
            };
          };
        };
      };
    };
  };
}
