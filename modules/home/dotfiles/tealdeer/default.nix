{
  config,
  lib,
  username,
  ...
}:

let
  cfg = config.modules.home.tealdeer;
in
{
  options.modules.home.tealdeer.enable = lib.mkEnableOption "tealdeer";

  config = lib.mkIf cfg.enable {
    home-manager.users.${username}.programs.tealdeer = {
      enable = true;
      enableAutoUpdates = true;

      settings = {
        display = {
          compact = true;
          use_pager = true;
        };

        updates.auto_update = true;
      };
    };
  };
}
