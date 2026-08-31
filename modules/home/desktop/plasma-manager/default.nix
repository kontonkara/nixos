{
  config,
  inputs,
  lib,
  username,
  ...
}:

let
  cfg = config.modules.home.plasmaManager;
in
{
  options.modules.home.plasmaManager.enable =
    lib.mkEnableOption "declarative KDE Plasma configuration";

  config = lib.mkIf cfg.enable {
    home-manager = {
      users = {
        ${username} = {
          imports = [
            inputs.plasma-manager.homeModules.plasma-manager

            ./appearance.nix
            ./konsole/module.nix
          ];

          programs.plasma = {
            enable = true;

            # Plasma is migrated incrementally. Settings that are not explicitly
            # managed by plasma-manager remain untouched.
            overrideConfig = false;
          };
        };
      };
    };
  };
}
