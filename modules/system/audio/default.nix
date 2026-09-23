{ config, lib, ... }:

let
  cfg = config.modules.system.audio;
in
{
  options = {
    modules = {
      system = {
        audio = {
          enable = lib.mkEnableOption "pipewire audio";
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    services = {
      pipewire = {
        enable = true;
        pulse = {
          enable = true;
        };
      };
    };
  };
}
