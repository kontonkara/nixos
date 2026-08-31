{
  config,
  lib,
  pkgs,
  username,
  ...
}:

let
  cfg = config.modules.home.duf;
in
{
  options.modules.home.duf.enable = lib.mkEnableOption "duf disk-usage utility";

  config = lib.mkIf cfg.enable {
    home-manager = {
      users = {
        ${username} = {
          home = {
            packages = [
              pkgs.duf
            ];
          };
        };
      };
    };
  };
}
