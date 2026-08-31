{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.modules.programs.msi-gpu-switcher;
  msi-gpu-switcher = pkgs.callPackage ../../../pkgs/msi-gpu-switcher/package.nix { };
in
{
  options = {
    modules = {
      programs = {
        msi-gpu-switcher = {
          enable = lib.mkEnableOption "MSI GPU MUX switching utility";
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    environment = {
      systemPackages = [ msi-gpu-switcher ];
    };
  };
}
