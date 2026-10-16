{ config, lib, ... }:

let
  cfg = config.modules.system.msi-ec;
in
{
  options = {
    modules = {
      system = {
        msi-ec = {
          enable = lib.mkEnableOption "the upstream msi-ec embedded controller driver";
        };
      };
    };
  };

  # Modes and the charge limit are ryukaze's (modules/system/services/ryukaze).
  config = lib.mkIf cfg.enable {
    boot = {
      extraModulePackages = [
        (config.boot.kernelPackages.callPackage ../../../pkgs/msi-ec { })
      ];

      # msi-ec has no modalias, so nothing autoloads it.
      kernelModules = [
        "msi-ec"
      ];
    };
  };
}
