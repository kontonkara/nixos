{ config, lib, ... }:

let
  cfg = config.modules.system.graphics.amd;
in
{
  imports = [
    ./mesa.nix
  ];

  options = {
    modules = {
      system = {
        graphics = {
          amd = {
            enable = lib.mkEnableOption "amd graphics";

            mesa = {
              cpuArch = lib.mkOption {
                type = lib.types.nullOr lib.types.str;
                default = null;
                description = "cpu architecture used for host-specific mesa builds, or null for a portable build.";
              };

              optimizationLevel = lib.mkOption {
                type = lib.types.nullOr (lib.types.ints.between 0 3);
                default = null;
                description = "meson optimization level for mesa, or null to keep the package default.";
              };

              disableAssertions = lib.mkOption {
                type = lib.types.bool;
                default = false;
                description = "disable mesa assertions for a smaller, faster release build.";
              };
            };
          };
        };
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
