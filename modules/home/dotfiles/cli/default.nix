{
  config,
  lib,
  pkgs,
  username,
  ...
}:

let
  cfg = config.modules.home.cli;
in
{
  options.modules.home.cli.enable = lib.mkEnableOption "declarative CLI environment";

  config = lib.mkIf cfg.enable {
    home-manager.users.${username} = {
      home = {
        packages = with pkgs; [
          duf
          dust
          procs
        ];

        sessionVariables.MANPAGER = "sh -c 'col -bx | bat -l man -p'";
      };

      programs = {
        bat = {
          enable = true;
          config = {
            decorations = "auto";
            diff-context = "3";
            italic-text = "always";
            pager = "less -FR";
            paging = "auto";
            style = "numbers,changes,header";
            tabs = "2";
            wrap = "never";
          };
        };

        eza = {
          enable = true;
          colors = "auto";
          enableFishIntegration = true;
          git = true;
          icons = "auto";
          extraOptions = [
            "--classify=auto"
            "--group-directories-first"
            "--header"
            "--hyperlink"
            "--time-style=long-iso"
          ];
        };

        fd = {
          enable = true;
          hidden = true;
          extraOptions = [ "--follow" ];
          ignores = [
            ".cache/"
            ".direnv/"
            ".git/"
            ".jj/"
            ".next/"
            ".nuxt/"
            ".pytest_cache/"
            ".venv/"
            "__pycache__/"
            "build/"
            "coverage/"
            "dist/"
            "node_modules/"
            "result"
            "result-*"
            "target/"
          ];
        };

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

        htop = {
          enable = true;
          settings = {
            config_reader_min_version = 3;
            detailed_cpu_time = true;
            header_margin = true;
            hide_kernel_threads = true;
            hide_userland_threads = true;
            highlight_base_name = true;
            show_cpu_frequency = true;
            show_cpu_temperature = true;
            show_cpu_usage = true;
            show_program_path = false;
            tree_view = true;
            header_layout = "two_50_50";
            column_meters_0 = [
              "LeftCPUs2"
              "Memory"
              "Zram"
            ];
            column_meter_modes_0 = [
              1
              1
              1
            ];
            column_meters_1 = [
              "RightCPUs2"
              "Tasks"
              "LoadAverage"
              "Uptime"
              "DiskIO"
              "Battery"
            ];
            column_meter_modes_1 = [
              1
              2
              2
              2
              2
              2
            ];
          };
        };

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

        starship = {
          enable = true;
          enableFishIntegration = true;
          settings = {
            add_newline = false;
            command_timeout = 1000;
            format = "$directory$git_branch$git_status$nix_shell$cmd_duration$character";
            right_format = "$status$jobs";
            scan_timeout = 30;

            character = {
              success_symbol = "[➜](bold green)";
              error_symbol = "[➜](bold red)";
            };
            cmd_duration = {
              format = "took [$duration]($style) ";
              min_time = 500;
            };
            directory = {
              fish_style_pwd_dir_length = 1;
              read_only = " ro";
              truncation_length = 3;
              truncate_to_repo = false;
            };
            git_branch = {
              format = "on [$symbol$branch(:$remote_branch)]($style) ";
              symbol = "git ";
            };
            git_status = {
              conflicted = "=";
              ahead = "⇡";
              behind = "⇣";
              diverged = "⇕";
              untracked = "?";
              stashed = "$";
              modified = "*";
              staged = "+";
              renamed = "»";
              deleted = "-";
            };
            hostname.disabled = true;
            jobs = {
              format = "[$symbol$number]($style) ";
              symbol = "jobs ";
            };
            nix_shell = {
              format = "via [$symbol$state( \\($name\\))]($style) ";
              impure_msg = "impure";
              pure_msg = "pure";
              symbol = "nix ";
            };
            package.disabled = true;
            status = {
              disabled = false;
              format = "[$symbol$status]($style) ";
            };
            username.disabled = true;
          };
        };

        tealdeer = {
          enable = true;
          enableAutoUpdates = true;
          settings = {
            display = {
              compact = true;
              use_pager = true;
            };
            updates.auto_update = true;
          };
        };

        zoxide = {
          enable = true;
          enableFishIntegration = true;
          options = [
            "--cmd"
            "cd"
          ];
        };
      };
    };
  };
}
