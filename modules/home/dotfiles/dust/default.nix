{
  config,
  lib,
  pkgs,
  username,
  ...
}:

let
  cfg = config.modules.home.dust;
in
{
  options.modules.home.dust.enable = lib.mkEnableOption "dust";

  config = lib.mkIf cfg.enable {
    home-manager.users.${username}.home.packages = [
      pkgs.dust
    ];
  };
}
