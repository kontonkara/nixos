{ config, lib, ... }:

{
  imports = [
    ./mesa.nix
  ];

  options.modules.graphics.amd.enable = lib.mkEnableOption "AMD graphics";

  config = lib.mkIf config.modules.graphics.amd.enable {
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
