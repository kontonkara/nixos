{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.modules.graphics.nvidia;

  nvidiaPackages = config.boot.kernelPackages.nvidiaPackages;
  runtimeD3NotifyPatch = pkgs.fetchurl {
    url = "https://github.com/NVIDIA/open-gpu-kernel-modules/pull/1299.patch";
    hash = "sha256-O9kTxyqjbG9Vx+z0sE14zZptfkCAwZgKRhJdYnwUmaY=";
  };
  nvidiaPackage = nvidiaPackages.latest // {
    open = nvidiaPackages.latest.open.overrideAttrs (oldAttrs: {
      installFlags = (oldAttrs.installFlags or [ ]) ++ [ "INSTALL_MOD_STRIP=1" ];
      patches =
        (oldAttrs.patches or [ ]) ++ lib.optional cfg.runtimeD3NotifyFix.enable runtimeD3NotifyPatch;
    });
  };
in
{
  options = {
    modules = {
      graphics = {
        nvidia = {
          enable = lib.mkEnableOption "NVIDIA hybrid graphics";

          dynamicBoost = {
            enable = lib.mkEnableOption "NVIDIA Dynamic Boost power balancing";
          };

          runtimeD3NotifyFix = {
            enable = lib.mkEnableOption "deferring NVIDIA NVPCF notifications until runtime resume";
          };
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
          amdgpuBusId = "PCI:6:0:0";
          nvidiaBusId = "PCI:1:0:0";
        };
      };
    };
  };
}
