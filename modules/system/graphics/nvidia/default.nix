{ config, lib, ... }:

let
  cfg = config.modules.system.graphics.nvidia;
in
{
  options = {
    modules = {
      system = {
        graphics = {
          nvidia = {
            enable = lib.mkEnableOption "nvidia hybrid graphics";

            dynamicBoost = {
              enable = lib.mkEnableOption "nvidia dynamic boost power balancing";
            };
          };
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    services = {
      xserver = {
        videoDrivers = [
          "nvidia"
        ];
      };
    };

    hardware = {
      nvidia = {
        open = true;
        nvidiaSettings = true;
        package = config.boot.kernelPackages.nvidiaPackages.latest;
        dynamicBoost = {
          enable = cfg.dynamicBoost.enable;
        };
        moduleParams = {
          nvidia = {
            NVreg_EnableResizableBar = 1;
          };
        };
        modesetting = {
          enable = true;
        };
        powerManagement = {
          enable = true;
          finegrained = true;
        };
        prime = {
          offload = {
            enable = true;
            enableOffloadCmd = true;
          };
          # Radeon 610M iGPU / RTX 4070 Laptop on this MSI chassis
          amdgpuBusId = "PCI:6:0:0";
          nvidiaBusId = "PCI:1:0:0";
        };
      };
    };
  };
}
