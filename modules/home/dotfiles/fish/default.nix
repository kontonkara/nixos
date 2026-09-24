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
              '';

              shellAbbrs = {
                ".." = "cd ..";
                "..." = "cd ../..";
                c = "code";

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
          # search and previews, done needs jq (niri window id) and notify-send.
          home = {
            packages = [
              pkgs.fd
              pkgs.bat
              pkgs.jq
              pkgs.libnotify
            ];
          };
        };
      };
    };
  };
}
