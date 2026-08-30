{ config, lib, ... }:

let
  cfg = config.modules.audio;
in
{
  options = {
    modules = {
      audio = {
        enable = lib.mkEnableOption "PipeWire audio";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    security.rtkit.enable = true;

    services = {
      pulseaudio = {
        enable = false;
      };

      pipewire = {
        enable = true;
        pulse = {
          enable = true;
        };
        alsa = {
          enable = true;
          support32Bit = true;
        };
        jack = {
          enable = false;
        };
        wireplumber = {
          enable = true;
          extraConfig = {
            "50-bluetooth-hfp" = {
              "wireplumber.settings" = {
                "bluetooth.autoswitch-to-headset-profile" = false;
              };
            };
          };
        };
      };
    };
  };
}
