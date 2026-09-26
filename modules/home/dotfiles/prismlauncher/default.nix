{ config, lib, pkgs, username, ... }:

let
  cfg = config.modules.home.prismlauncher;
in
{
  options = {
    modules = {
      home = {
        prismlauncher = {
          enable = lib.mkEnableOption "prism launcher with zulu jdks";
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    home-manager = {
      users = {
        ${username} = {
          programs = {
            prismlauncher = {
              enable = true;
              # Every Java that Minecraft versions need: 8 up to 1.16, 17
              # for 1.17-1.20.4, 21 from 1.20.5, 25 for the newest.
              package = pkgs.prismlauncher.override {
                jdks = with pkgs; [
                  zulu8
                  zulu17
                  zulu21
                  zulu25
                ];
              };

              # Merged into the writable prismlauncher.cfg on each switch.
              settings = {
                # Instances start on the RTX (PRIME offload env); the
                # launcher itself stays on the iGPU.
                UseDiscreteGpu = true;
              };
            };
          };
        };
      };
    };
  };
}
