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
  options.modules.home.duf.enable = lib.mkEnableOption "duf";

  config = lib.mkIf cfg.enable {
    home-manager.users.${username}.home.packages = [
      pkgs.duf
    ];
  };
}
