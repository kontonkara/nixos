{
  config,
  lib,
  ...
}:

let
  cfg = config.modules.graphics.nvidia;

  nvidiaPackages = config.boot.kernelPackages.nvidiaPackages;
  nvidiaPackage =
    if nvidiaPackages ? cachyos then
      let
        basePackage = nvidiaPackages.cachyos;
      in
      basePackage
      // {
        open = basePackage.open.overrideAttrs (oldAttrs: {
          installFlags = (oldAttrs.installFlags or [ ]) ++ [ "INSTALL_MOD_STRIP=1" ];
        });
      }
    else
      nvidiaPackages.latest;
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
        package = nvidiaPackage;
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
          amdgpuBusId = "PCI:6:0:0";
          nvidiaBusId = "PCI:1:0:0";
        };
      };
    };
  };
}
