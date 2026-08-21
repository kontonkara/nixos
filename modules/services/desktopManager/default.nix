{ config, lib, ... }:

let
  cfg = config.modules.desktop.plasma;
in
{
  options = {
    modules = {
      desktop = {
        plasma = {
          enable = lib.mkEnableOption "Plasma desktop";
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    services = {
      desktopManager = {
        plasma6 = {
          enable = true;
        };
      };
    };
  };
}
