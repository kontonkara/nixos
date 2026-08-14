{ pkgs, username, ... }:

{
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
}
