{ config, lib, pkgs, username, ... }:

let
  cfg = config.modules.home.obs-studio;
in
{
  options = {
    modules = {
      home = {
        obs-studio = {
          enable = lib.mkEnableOption "obs studio";
        };
      };
    };
  };

  # Screen capture is "Screen Capture (PipeWire)" via the gnome portal.
  # Every launch briefly wakes the RTX: obs-nvenc probes NVENC in a
  # subprocess (obs-nvenc-test), and the AV1 VAAPI probe moves on to
  # renderD129 because the 610M has no AV1 encoder. NVENC needs no
  # nvidia-offload but keeps the RTX awake while recording; the VAAPI
  # H.264/HEVC encoders on renderD128 (610M) leave it asleep.
  # No virtual camera: that is the NixOS module's v4l2loopback, an
  # out-of-tree module rebuilt against the local kernel.
  config = lib.mkIf cfg.enable {
    home-manager = {
      users = {
        ${username} = {
          programs = {
            obs-studio = {
              enable = true;
              plugins = [
                # Per-application audio sources (a game without Vesktop's
                # voice); stock OBS on Linux only captures whole devices.
                pkgs.obs-studio-plugins.obs-pipewire-audio-capture
              ];
            };
          };
        };
      };
    };
  };
}
