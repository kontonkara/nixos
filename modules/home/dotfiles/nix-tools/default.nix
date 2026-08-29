{
  config,
  lib,
  pkgs,
  username,
  ...
}:

let
  cfg = config.modules.home.nixTools;
in
{
  options.modules.home.nixTools.enable = lib.mkEnableOption "Nix development and maintenance tools";

  config = lib.mkIf cfg.enable {
    programs.nh = {
      enable = true;
      flake = "/home/${username}/nixos";

      clean = {
        enable = true;
        dates = "weekly";
        extraArgs = "--keep-since 14d --keep 10";
      };
    };

    home-manager.users.${username} = {
      home.packages = with pkgs; [
        comma
        nvd
      ];

      programs = {
        direnv = {
          enable = true;
          enableFishIntegration = true;
          silent = true;
          config.global = {
            hide_env_diff = true;
            strict_env = true;
            warn_timeout = "1m";
          };
          nix-direnv.enable = true;
        };

        nix-index = {
          enable = true;
          enableFishIntegration = true;
        };
      };

      systemd.user = {
        services.nix-index-update = {
          Unit.Description = "update the nix-index database";
          Service = {
            Type = "oneshot";
            ExecStart = "${pkgs.nix-index}/bin/nix-index";
          };
        };

        timers.nix-index-update = {
          Unit.Description = "update the nix-index database weekly";
          Timer = {
            OnCalendar = "weekly";
            Persistent = true;
          };
          Install.WantedBy = [ "timers.target" ];
        };
      };
    };
  };
}
