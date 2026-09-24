{ config, lib, pkgs, ... }:

let
  cfg = config.modules.programs.steam;
in
{
  options = {
    modules = {
      programs = {
        steam = {
          enable = lib.mkEnableOption "steam with ge-proton";
        };
      };
    };
  };

  # Steam itself stays on the iGPU; games go to the RTX per title with the
  # launch option `nvidia-offload %command%` (the FHS env keeps host PATH).
  config = lib.mkIf cfg.enable {
    programs = {
      steam = {
        enable = true;
        extraCompatPackages = [
          pkgs.proton-ge-bin
        ];
        # niri has no EIS/RemoteDesktop, so Steam Input's XTEST only reaches
        # Wayland windows through extest (still valid for the 32-bit client).
        extest = {
          enable = true;
        };
      };
    };
  };
}
