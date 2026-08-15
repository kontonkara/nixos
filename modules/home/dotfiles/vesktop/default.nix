{
  config,
  lib,
  pkgs,
  username,
  ...
}:

let
  cfg = config.modules.home.vesktop;
in
{
  options.modules.home.vesktop.enable = lib.mkEnableOption "Vesktop home configuration";

  config = lib.mkIf cfg.enable {
    nixpkgs = {
      overlays = [
        (import ./openh264-overlay.nix)
      ];
    };

    home-manager = {
      users = {
        ${username} = {
          programs = {
            vesktop = {
              enable = true;
              package = pkgs.vesktop;
            };
          };
        };
      };
    };
  };
}
