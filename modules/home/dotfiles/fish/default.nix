{ config, lib, username, pkgs, ... }:

let
  cfg = config.modules.home.fish;
in
{
  options = {
    modules = {
      home = {
        fish = {
          enable = lib.mkEnableOption "fish shell config and plugins";
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
                set -g fish_greeting

                # fzf.fish: ISO dates like eza's long-iso (the default is
                # month-day), eza trees for directories, delta for git diffs.
                set -g fzf_history_time_format "%F %R"
                set -g fzf_preview_dir_cmd eza --tree --level=2 --group-directories-first --color=always --icons=always
                set -g fzf_diff_highlighter delta --paging=never --width=20
              '';

              shellAbbrs = {
                # bash's `!!` (e.g. `sudo !!`), expanded in place before it runs.
                "!!" = {
                  position = "anywhere";
                  function = "last_history_item";
                };
                ".." = "cd ..";
                "..." = "cd ../..";
                c = "zeditor";

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

                nb = "nix build";
                ncg = "nix-collect-garbage";
                nd = "nix develop";
                nf = "nix flake";
                nfc = "nix flake check";
                nfm = "nix flake metadata";
                # nh has no `flake` subcommand; `nh os switch -u` updates and
                # switches in one go.
                nfu = "nix flake update";
                # Bare `nh clean all` keeps a single generation; use the
                # weekly timer's retention instead.
                ngc = "nh clean all ${config.programs.nh.clean.extraArgs}";
                nhb = "nh os boot";
                nhs = "nh os switch";
                nht = "nh os test";
                ns = {
                  expansion = "nix shell nixpkgs#%";
                  setCursor = true;
                };
                nsp = "nix search nixpkgs";
              };

              functions = {
                last_history_item = {
                  description = "print the previous command line";
                  body = ''
                    echo -- $history[1]
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
              };

              # Command wrappers that ship no completions: complete the wrapped
              # command and its arguments, as fish does for sudo.
              completions = lib.genAttrs [
                "gamemoderun"
                "mangohud"
                "nvidia-offload"
                "steam-run"
              ] (command: "complete --command ${command} --no-files --arguments '(__fish_complete_subcommand)'");

              plugins = [
                {
                  name = "autopair";
                  src = pkgs.fishPlugins.autopair.src;
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

            fzf = {
              enable = true;
              # HM's `fzf --fish | source` would rebind Ctrl+R over fzf.fish.
              enableFishIntegration = false;
            };
          };

          # Runtime deps of the plugins: fzf.fish needs fd/bat for directory
          # search and previews (eza/delta for the ones set above), done needs
          # jq (niri window id) and notify-send.
          home = {
            packages = [
              pkgs.fd
              pkgs.bat
              pkgs.eza
              pkgs.delta
              pkgs.jq
              pkgs.libnotify
            ];
          };
        };
      };
    };
  };
}
