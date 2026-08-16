{ config, lib, ... }:

let
  cfg = config.modules.graphics.amd;
in

{
  imports = [
    ./mesa.nix
  ];

  options.modules.graphics.amd = {
    enable = lib.mkEnableOption "AMD graphics";

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

  config = lib.mkIf cfg.enable {
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
