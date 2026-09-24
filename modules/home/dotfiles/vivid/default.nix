{ config, lib, username, ... }:

let
  cfg = config.modules.home.vivid;
in
{
  options = {
    modules = {
      home = {
        vivid = {
          enable = lib.mkEnableOption "vivid LS_COLORS generator";
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    home-manager = {
      users = {
        ${username} = {
          programs = {
            # The theme comes from stylix's vivid target; fish exports
            # LS_COLORS for eza, fd and ls.
            vivid = {
              enable = true;
            };
          };
        };
      };
    };
  };
}
