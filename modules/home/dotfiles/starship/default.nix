{
  config,
  lib,
  username,
  ...
}:

let
  cfg = config.modules.home.starship;
in
{
  options.modules.home.starship.enable = lib.mkEnableOption "starship";

  config = lib.mkIf cfg.enable {
    home-manager.users.${username}.programs.starship = {
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
  };
}
