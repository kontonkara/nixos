{ config, lib, ... }:

let
  cfg = config.modules.graphics.amd;
in

{
  imports = [
    ./mesa.nix
  ];

  options = {
    modules = {
      graphics = {
        amd = {
          enable = lib.mkEnableOption "AMD graphics";

          kernel = {
            builtIn = {
              enable = lib.mkEnableOption "building AMDGPU into the kernel image";
            };

            removeUnsupportedRgba8888 = {
              enable = lib.mkEnableOption "the AMDGPU workaround for unsupported DRM_FORMAT_RGBA8888 scanout";
            };

            trimUnsupportedHardware = {
              enable = lib.mkEnableOption "removing AMDGPU support for hardware absent from this host";
            };
          };

          mesa = {
            cpuArch = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
              description = "CPU architecture used for host-specific Mesa builds, or null for a portable build.";
            };

            optimizationLevel = lib.mkOption {
              type = lib.types.nullOr (lib.types.ints.between 0 3);
              default = null;
              description = "Meson optimization level for Mesa, or null to keep the package default.";
            };

            disableAssertions = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = "Disable Mesa assertions for a smaller, faster release build.";
            };
          };
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    boot.kernelPatches =
      lib.optional cfg.kernel.removeUnsupportedRgba8888.enable {
        name = "amdgpu-do-not-advertise-unsupported-rgba8888";
        patch = ./remove-unsupported-rgba8888.patch;
      }
      ++ lib.optional cfg.kernel.builtIn.enable {
        name = "amdgpu-built-in";
        patch = null;
        structuredExtraConfig = {
          DRM_AMDGPU = lib.kernel.yes;
        };
      }
      ++ lib.optional cfg.kernel.trimUnsupportedHardware.enable {
        name = "amdgpu-trim-unsupported-hardware";
        patch = null;
        structuredExtraConfig = {
          DRM_AMDGPU_CIK = lib.kernel.no;
          DRM_AMDGPU_SI = lib.kernel.no;
          DRM_AMD_ISP = lib.kernel.no;
          DRM_AMD_SECURE_DISPLAY = lib.kernel.no;
        };
      };

    hardware = {
      graphics = {
        enable = true;
        enable32Bit = true;
      };

      amdgpu = {
        initrd = {
          enable = true;
        };
      };
    };
  };
}
