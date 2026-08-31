{
  config,
  lib,
  username,
  ...
}:

let
  cfg = config.modules.home.zoxide;
in
{
  options.modules.home.zoxide.enable = lib.mkEnableOption "zoxide directory-jumping configuration";

  config = lib.mkIf cfg.enable {
    home-manager = {
      users = {
        ${username} = {
          programs = {
            zoxide = {
              enable = true;
              enableFishIntegration = true;

              options = [
                "--cmd"
                "cd"
              ];
            };
          };
        };
      };
    };
  };
}
