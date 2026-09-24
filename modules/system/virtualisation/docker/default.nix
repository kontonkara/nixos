{ config, lib, ... }:

let
  cfg = config.modules.system.virtualisation.docker;
in
{
  options = {
    modules = {
      system = {
        virtualisation = {
          docker = {
            enable = lib.mkEnableOption "docker engine";
          };
        };
      };
    };
  };

  # `docker compose` and buildx come with the package as CLI plugins.
  config = lib.mkIf cfg.enable {
    virtualisation = {
      docker = {
        enable = true;
        # `docker system prune -f`: stopped containers, dangling images, unused
        # networks and build cache; volumes are kept.
        autoPrune = {
          enable = true;
          dates = "weekly";
        };
      };
    };
  };
}
