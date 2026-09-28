{ config, lib, pkgs, username, ... }:

let
  cfg = config.modules.home.noctalia;

  hmConfig = config.home-manager.users.${username};

  # The monitors are niri's outputs, set per host.
  lockscreenWidgets = import ./lockscreen.nix {
    inherit lib;
    inherit (config.modules.home.niri) outputs;
  };
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
              package = pkgs.noctalia.overrideAttrs (oldAttrs: {
                patches = (oldAttrs.patches or [ ]) ++ [
                  # No Settings button in the Control Center header: settings
                  # are made here, and the window's changes don't last.
                  ./hide-settings-button.patch
                ];
              });
              systemd = {
                enable = true;
              };

              # Every key spelled out; stylix's noctalia target adds the palette,
              # theme mode, font and dock/notification/OSD opacity on top.
              settings = import ./settings.nix {
                inherit pkgs lockscreenWidgets;
                inherit (hmConfig.home) homeDirectory;
              };
            };
          };

          # The Settings window, the lock screen editor and Noctalia's own
          # fix-ups save to this file, and it wins over config.toml. Kept to
          # the bare version marker (the current one, so no migration rewrites
          # it); Noctalia replaces the link with a plain file when it saves,
          # and every switch puts it back.
          xdg = {
            stateFile = {
              "noctalia/settings.toml" = {
                text = ''
                  config_version = 14
                '';
                force = true;
              };
            };
          };
        };
      };
    };
  };
}
