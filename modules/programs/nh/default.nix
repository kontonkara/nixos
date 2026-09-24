{ config, lib, username, ... }:

let
  cfg = config.modules.programs.nh;
in
{
  options = {
    modules = {
      programs = {
        nh = {
          enable = lib.mkEnableOption "nh with scheduled store cleanup";
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    programs = {
      nh = {
        enable = true;
        flake = "/home/${username}/nixos";

        clean = {
          enable = true;
          dates = "weekly";
          # Without flags nh keeps a single generation; --keep-one also
          # spares the newest gcroot of each direnv project.
          extraArgs = "--keep-since 14d --keep 10 --keep-one";
        };
      };
    };
  };
}
