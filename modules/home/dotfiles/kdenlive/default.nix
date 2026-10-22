{ config, lib, pkgs, username, ... }:

let
  cfg = config.modules.home.kdenlive;
in
{
  options = {
    modules = {
      home = {
        kdenlive = {
          enable = lib.mkEnableOption "kdenlive";
        };
      };
    };
  };

  # Opens the phone's HEVC/H.264 and AAC as they are, unlike Resolve's free
  # edition. Renders encode with VAAPI on the 610M or NVENC on the RTX.
  config = lib.mkIf cfg.enable {
    home-manager = {
      users = {
        ${username} = {
          home = {
            packages = [
              pkgs.kdePackages.kdenlive
            ];
          };
        };
      };
    };
  };
}
