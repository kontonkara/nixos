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
        # Not at boot: docker.socket starts the daemon at the first `docker`
        # command.
        enableOnBoot = false;
        # `docker system prune -f`: stopped containers, dangling images, unused
        # networks and build cache; volumes are kept.
        autoPrune = {
          enable = true;
          dates = "weekly";
        };
      };
    };

    systemd = {
      services = {
        # The weekly prune would otherwise start the daemon and leave it
        # running: it only runs when docker already does.
        docker-prune = {
          requires = lib.mkForce [ ];
          serviceConfig = {
            ExecCondition = "${lib.getExe' config.systemd.package "systemctl"} is-active --quiet docker.service";
          };
        };
      };
    };
  };
}
