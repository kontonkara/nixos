{ config, lib, ... }:

let
  cfg = config.modules.system.graphics.nvidia;

  driver = config.boot.kernelPackages.nvidiaPackages.latest;
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

            # No defaults: bus IDs differ per machine (lspci, in decimal).
            prime = {
              amdgpuBusId = lib.mkOption {
                type = lib.types.str;
                example = "PCI:6:0:0";
                description = "PCI bus ID of the AMD iGPU that drives the panel.";
              };

              nvidiaBusId = lib.mkOption {
                type = lib.types.str;
                example = "PCI:1:0:0";
                description = "PCI bus ID of the NVIDIA dGPU used for offload.";
              };
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
        # 615 probes the GPU from its own kthread, where Linux 7.3 gives no
        # real root, so opening the device's sysfs config file fails and
        # runtime D3 turns "Not supported": the RTX never powers off. The
        # patch probes in modprobe's context instead.
        package = driver // {
          open = driver.open.overrideAttrs (old: {
            patches = (old.patches or [ ]) ++ [ ./probe-in-caller-context.patch ];
          });
        };
        dynamicBoost = {
          enable = cfg.dynamicBoost.enable;
        };
        moduleParams = {
          nvidia = {
            NVreg_EnableResizableBar = 1;
            # Write-combined system memory mappings through PAT instead of
            # MTRRs; a CachyOS default.
            NVreg_UsePageAttributeTable = 1;
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
          inherit (cfg.prime) amdgpuBusId nvidiaBusId;
        };
      };
    };
  };
}
