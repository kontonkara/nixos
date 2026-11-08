{ config, lib, inputs, username, ... }:

let
  cfg = config.modules.home.spotify;
in
{
  options = {
    modules = {
      home = {
        spotify = {
          enable = lib.mkEnableOption "spotify patched by spicetify";
        };
      };
    };
  };

  # Spicetify with no extensions, apps or snippets: the theme is stylix's
  # spicetify target as it comes.
  config = lib.mkIf cfg.enable {
    home-manager = {
      sharedModules = [
        inputs.spicetify-nix.homeManagerModules.default
      ];

      users = {
        ${username} = {
          programs = {
            spicetify = {
              enable = true;
            };
          };
        };
      };
    };
  };
}
