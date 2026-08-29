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
  options = {
    modules = {
      home = {
        fish = {
          enable = lib.mkEnableOption "Fish home configuration";
        };
      };
    };
  };

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

                path-dedupe
              '';

              shellAliases = {
                cat = "bat --paging=never";
                catp = "bat";
                df = "duf --hide special --hide-fs tmpfs,devtmpfs --sort mountpoint";
                dfa = "duf --all";
                dfi = "duf --inodes";
                du = "dust --depth 2";
                dua = "dust --depth 2 --reverse";
                dufiles = "dust --only-file --reverse";
                dus = "dust --depth 1";
                find = "fd";
                grep = "rg";
                l = "eza";
                la = "eza --all --long";
                ld = "eza --only-dirs";
                lf = "eza --only-files";
                lg = "eza --long --git --git-repos";
                ll = "eza --long";
                lla = "eza --all --long --git";
                ls = "eza";
                lsize = "eza --long --total-size --sort=size --reverse";
                lt = "eza --tree --level=2";
                ps = "procs";
                psc = "procs --sortd UsageCpu";
                psm = "procs --sortd UsageMem";
                pst = "procs --tree";
                top = "htop";
                tree = "eza --tree --level=3";
              };

              shellAbbrs = {
                ".." = "cd ..";
                "..." = "cd ../..";
                c = "code";
                cdi = "cd -i";
                g = "git";
                ga = "git add";
                gaa = "git add --all";
                gb = "git branch";
                gc = "git commit";
                gca = "git commit --amend";
                gcan = "git commit --amend --no-edit";
                gcm = "git commit --message";
                gd = "git diff";
                gds = "git diff --staged";
                gf = "git fetch";
                gfa = "git fetch --all --prune";
                gl = "git log --oneline --graph --decorate";
                gp = "git push";
                gpl = "git pull";
                grb = "git rebase";
                grbi = "git rebase --interactive";
                gs = "git status --short";
                gst = "git status";
                za = "zoxide add";
                zq = "zoxide query";
                zr = "zoxide remove";
              };

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

              functions = {
                croot = {
                  description = "change directory to the current git root";
                  body = ''
                    set -l root (git rev-parse --show-toplevel 2>/dev/null)

                    if test -z "$root"
                      echo "not in a git repository" >&2
                      return 1
                    end

                    cd "$root"
                  '';
                };

                mkcd = {
                  description = "create a directory and enter it";
                  body = ''
                    if test (count $argv) -ne 1
                      echo "usage: mkcd <directory>" >&2
                      return 2
                    end

                    mkdir -p -- $argv[1]
                    and cd -- $argv[1]
                  '';
                };

                path-dedupe = {
                  description = "remove duplicate entries from PATH";
                  body = ''
                    set -l seen
                    set -l deduped

                    for entry in $PATH
                      if not contains -- $entry $seen
                        set --append seen $entry
                        set --append deduped $entry
                      end
                    end

                    set -gx PATH $deduped
                  '';
                };

                tmpcd = {
                  description = "create a temporary directory and enter it";
                  body = ''
                    set -l dir (mktemp -d)

                    if test -z "$dir"
                      return 1
                    end

                    cd "$dir"
                  '';
                };
              };
            };
          };
        };
      };
    };
  };
}
