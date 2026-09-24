{ config, lib, pkgs, username, inputs, ... }:

let
  cfg = config.modules.home.niri;

  # Layout colors come from stylix's palette like the rest of the desktop;
  # niri-flake's stylix target only covers the border and the cursor.
  colors = config.home-manager.users.${username}.lib.stylix.colors.withHashtag;
  accent = colors.${config.modules.home.stylix.accent};
in
{
  options = {
    modules = {
      home = {
        niri = {
          enable = lib.mkEnableOption "niri home configuration";
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    nixpkgs.overlays = [
      # niri-flake's make-niri still requires libdisplay-info 0.2.0 and
      # callPackage resolves the removed attr before any .override can run.
      # niri builds fine against 0.3 — only the assert is stale.
      (final: prev: {
        libdisplay-info_0_2 = prev.libdisplay-info_0_3.overrideAttrs (o: {
          version = "0.2.0";
          __intentionallyOverridingVersion = true;
        });
      })
      inputs.niri.overlays.niri
    ];

    programs = {
      niri = {
        enable = true;
        # Adds the `scaling-mode` output option and `niri msg output <name> scaling-mode`.
        # Must be rebased when flake.lock bumps niri-unstable.
        package = pkgs.niri-unstable.overrideAttrs (old: {
          patches = (old.patches or [ ]) ++ [ ./niri-scaling-mode.patch ];
        });
      };
    };

    xdg = {
      portal = {
        enable = true;
        xdgOpenUsePortal = true;
        config = {
          common = {
            default = [ "gnome" ];
          };
          niri = {
            default = lib.mkForce [
              "gnome"
              "gtk"
            ];
            # No FileChooser override: with Nautilus installed the GNOME
            # portal gives the GTK4 chooser (the gtk pin dated from Nemo).
            "org.freedesktop.impl.portal.ScreenCast" = [ "gnome" ];
            "org.freedesktop.impl.portal.Screenshot" = [ "gnome" ];
            "org.freedesktop.impl.portal.Access" = [ "gnome" ];
          };
        };
        extraPortals = with pkgs; [
          xdg-desktop-portal-gnome
          xdg-desktop-portal-gtk
        ];
      };
    };

    systemd = {
      user = {
        services = {
          xdg-desktop-portal-gnome = {
            serviceConfig = {
              UnsetEnvironment = [ "GDK_BACKEND" ];
            };
          };
        };
      };
    };

    home-manager = {
      users = {
        ${username} = { options, ... }: {
          programs = {
            niri = {
              # niri-flake's settings schema has no `scaling-mode` and niri doesn't merge
              # duplicate `output` sections, so append it to the rendered eDP-1 node.
              config =
                let
                  extraOutputNodes = {
                    "eDP-1" = [ (inputs.niri.lib.kdl.leaf "scaling-mode" "full") ];
                  };
                  addExtra =
                    node:
                    let
                      extra = extraOutputNodes.${lib.head node.arguments} or [ ];
                    in
                    if node.name == "output" then node // { children = node.children ++ extra; } else node;
                in
                map addExtra (lib.remove null (lib.flatten options.programs.niri.config.default));

              settings =
                let
                  decoration = import ./decoration.nix;
                  rules = import ./rules.nix;
                in
                {
                  input = import ./input.nix;
                  outputs = import ./outputs.nix;
                  layout = import ./layout.nix { inherit colors accent; };
                  inherit (decoration) prefer-no-csd animations;
                  inherit (rules) window-rules layer-rules;
                  spawn-at-startup = import ./startup.nix;
                  binds = import ./binds.nix;

                  hotkey-overlay = {
                    skip-at-startup = true;
                  };
                  xwayland-satellite = {
                    enable = true;
                  };
                  screenshot-path = "~/pictures/screenshots/%Y-%m-%dT%H:%M:%S.png";

                  debug = {
                    # Noctalia niri guide: lets notification actions and tray
                    # clicks focus apps (Telegram, Electron) that send
                    # activation tokens with invalid serials.
                    honor-xdg-activation-with-invalid-serial = [ ];
                  };
                };
            };
          };
        };
      };
    };
  };
}
