{ config, lib, username, ... }:

let
  cfg = config.modules.home.imv;
in
{
  options = {
    modules = {
      home = {
        imv = {
          enable = lib.mkEnableOption "imv image viewer";
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    home-manager = {
      users = {
        ${username} = {
          programs = {
            imv = {
              enable = true;
            };
          };

          xdg = {
            mimeApps = {
              defaultApplications = lib.genAttrs [
                "image/bmp"
                "image/gif"
                "image/jpeg"
                "image/png"
                "image/tiff"
                "image/webp"
              ] (_: [ "imv.desktop" ]);
            };
          };
        };
      };
    };
  };
}
