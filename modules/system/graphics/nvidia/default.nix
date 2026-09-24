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

    # Whenever niri renders on the RTX (MUX in dGPU mode, outputs wired to
    # it) the driver keeps freed VRAM pooled and niri grows by gigabytes. The
    # 615 driver ships this profile for KWin/mutter/wlroots/Hyprland but not
    # niri (niri wiki, Nvidia).
    environment = {
      etc = {
        "nvidia/nvidia-application-profiles-rc.d/50-limit-free-buffer-pool-in-wayland-compositors.json" = {
          text = builtins.toJSON {
            rules = [
              {
                pattern = {
                  feature = "procname";
                  matches = "niri";
                };
                profile = "Limit Free Buffer Pool On Wayland Compositors";
              }
            ];
            profiles = [
              {
                name = "Limit Free Buffer Pool On Wayland Compositors";
                settings = [
                  {
                    key = "GLVidHeapReuseRatio";
                    value = 0;
                  }
                ];
              }
            ];
          };
        };
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
            # PreserveVideoMemoryAllocations (set by powerManagement) dumps used
            # VRAM here on suspend; the default /tmp is a RAM-backed tmpfs now,
            # which NVIDIA's README warns against.
            NVreg_TemporaryFilePath = "/var/tmp";
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
