{ config, lib, ... }:

let
  cfg = config.modules.graphics.nvidia;
in
{
  options = {
    modules = {
      graphics = {
        nvidia = {
          enable = lib.mkEnableOption "NVIDIA hybrid graphics";
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    hardware = {
      nvidia = {
        open = true;
        nvidiaSettings = true;
        package = config.boot.kernelPackages.nvidiaPackages.latest;
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
          amdgpuBusId = "PCI:6:0:0";
          nvidiaBusId = "PCI:1:0:0";
        };
      };
    };
  };
}
