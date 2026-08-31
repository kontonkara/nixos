{
  config,
  lib,
  username,
  ...
}:

let
  cfg = config.modules.home.obsidian;
in
{
  options = {
    modules = {
      home = {
        obsidian = {
          enable = lib.mkEnableOption "Obsidian home configuration";
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    home-manager = {
      users = {
        ${username} = {
          programs = {
            obsidian = {
              enable = true;
              vaults = {
                devops-trainee.target = "documents/devops-trainee";
                personal.target = "documents/personal";
              };
            };
          };
        };
      };
    };
  };
}
