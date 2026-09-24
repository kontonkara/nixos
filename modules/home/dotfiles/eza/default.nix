{ config, lib, username, ... }:

let
  cfg = config.modules.home.eza;
in
{
  options = {
    modules = {
      home = {
        eza = {
          enable = lib.mkEnableOption "eza directory listing";
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    home-manager = {
      users = {
        ${username} = {
          programs = {
            eza = {
              enable = true;
              # Its fish integration abbreviates `ls` to eza, whose short
              # flags differ (`ls -ltr` breaks: eza's -t takes a field).
              enableFishIntegration = false;
              colors = "auto";
              git = true;
              # Nerd Font glyphs: kitty bundles them, other terminals need a
              # Nerd Font or show boxes.
              icons = "auto";

              extraOptions = [
                "--classify=auto"
                "--color-scale=age"
                "--color-scale-mode=gradient"
                "--group-directories-first"
                "--header"
                "--hyperlink"
                "--time-style=long-iso"
              ];
            };

            # The eza wrapper alias above still applies to these.
            fish = {
              shellAbbrs = {
                l = "eza";
                la = "eza --all --long";
                ld = "eza --only-dirs";
                lf = "eza --only-files";
                lg = "eza --long --git-repos";
                ll = "eza --long";
                lla = "eza --all --long";
                lsize = "eza --long --total-size --sort=size --reverse";
                lt = "eza --tree --level=2";
              };
            };
          };
        };
      };
    };
  };
}
