{ config, lib, username, ... }:

let
  cfg = config.modules.home.git;

  email = "kontonkara@gmail.com";
in
{
  options = {
    modules = {
      home = {
        git = {
          enable = lib.mkEnableOption "git version-control tooling";
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    home-manager = {
      users = {
        ${username} = {
          programs = {
            delta = {
              enable = true;
              enableGitIntegration = true;
              options = {
                # bat's theme on the terminal's 16 colours, which stylix sets
                # in kitty, VS Code and Zed; delta has no stylix target.
                syntax-theme = "base16";
                line-numbers = true;
                navigate = true;
              };
            };

            git = {
              enable = true;

              lfs = {
                enable = true;
              };

              signing = {
                format = "ssh";
                # A .pub path rather than key::, so ssh-keygen can fall back to
                # the private key next to it when the agent doesn't hold it.
                key = "~/.ssh/github.pub";
                # Lets `git log --show-signature` verify our own commits.
                allowedSigners = ''
                  ${email} namespaces="git" ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKcIhkx75Ml9wniea9JrPf0vioXP63gZac0O7zhL3/VM
                '';
              };

              ignores = [
                ".DS_Store"
                "Thumbs.db"
                ".direnv"
                ".envrc.local"
                "node_modules"
                "*.log"
                # nix build links.
                "result"
                "result-*"
                # Claude Code appends these to the global ignore file, which
                # is read-only here.
                "**/.claude/settings.local.json"
                "**/.claude/.cc-writes/"
              ];

              settings = {
                user = {
                  name = "Nikita Konton";
                  inherit email;
                };

                alias = {
                  amend = "commit --amend --no-edit";
                  br = "branch";
                  co = "checkout";
                  last = "log -1 HEAD";
                  lg = "log --color --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit";
                  root = "rev-parse --show-toplevel";
                  st = "status -sb";
                  undo = "reset --soft HEAD~1";
                  unstage = "reset HEAD --";
                };

                branch = {
                  sort = "-committerdate";
                };

                column = {
                  ui = "auto";
                };

                # Commits only: signByDefault also sets tag.gpgSign, which turns
                # every `git tag` into an annotated one that asks for a message.
                commit = {
                  gpgSign = true;
                  verbose = true;
                };

                core = {
                  whitespace = "space-before-tab,tab-in-indent,trailing-space";
                };

                diff = {
                  algorithm = "histogram";
                  # delta keeps git's moved-line colours.
                  colorMoved = "default";
                  colorMovedWS = "allow-indentation-change";
                };

                fetch = {
                  prune = true;
                };

                help = {
                  autocorrect = "prompt";
                };

                init = {
                  defaultBranch = "main";
                };

                merge = {
                  conflictStyle = "zdiff3";
                };

                pull = {
                  rebase = true;
                };

                push = {
                  autoSetupRemote = true;
                  followTags = true;
                };

                rebase = {
                  autoSquash = true;
                  autoStash = true;
                };

                rerere = {
                  enabled = true;
                  autoUpdate = true;
                };

                tag = {
                  sort = "version:refname";
                };
              };
            };
          };
        };
      };
    };
  };
}
