{ config, lib, pkgs, username, ... }:

let
  cfg = config.modules.home.noctalia;
in
{
  options = {
    modules = {
      home = {
        noctalia = {
          enable = lib.mkEnableOption "noctalia desktop shell";
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    # Noctalia is the polkit agent (shell.polkit_agent); two registered
    # agents would race for every prompt.
    systemd = {
      user = {
        services = {
          niri-flake-polkit = {
            enable = false;
          };
        };
      };
    };

    home-manager = {
      users = {
        ${username} = {
          programs = {
            noctalia = {
              enable = true;
              systemd = {
                enable = true;
              };

              # Every key spelled out; stylix's noctalia target adds the palette,
              # theme mode, font and dock/notification/OSD opacity on top.
              settings = import ./settings.nix { inherit pkgs; };
            };
          };
        };
      };
    };
  };
}
