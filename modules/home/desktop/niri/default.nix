{ config, lib, pkgs, username, inputs, ... }:

let
  cfg = config.modules.home.niri;

  # Layout colors come from stylix's palette like the rest of the desktop;
  # niri-flake's stylix target only covers the border and the cursor.
  palette = config.home-manager.users.${username}.lib.stylix.colors;
  colors = palette.withHashtag;
  accent = colors.${config.modules.home.stylix.accent};

  decoration = import ./decoration.nix {
    accentRgb = lib.concatMapStringsSep ", " (
      channel: palette."${config.modules.home.stylix.accent}-dec-${channel}"
    ) [ "r" "g" "b" ];
  };
in
{
  options = {
    modules = {
      home = {
        niri = {
          enable = lib.mkEnableOption "niri home configuration";

          # The monitors are the host's: set both from hosts/<host>.
          outputs = lib.mkOption {
            type = lib.types.attrsOf lib.types.anything;
            default = { };
            example = {
              "eDP-1" = {
                mode = {
                  width = 2560;
                  height = 1440;
                  refresh = 240.0;
                };
              };
            };
            description = "niri-flake output settings per connector.";
          };

          stretch = lib.mkOption {
            type = lib.types.nullOr (
              lib.types.submodule {
                options = {
                  output = lib.mkOption {
                    type = lib.types.str;
                    example = "eDP-1";
                    description = "Connector that gets scaling-mode \"full\".";
                  };

                  mode = lib.mkOption {
                    type = lib.types.str;
                    example = "1440x1080@240";
                    description = "4:3 custom mode Mod+Shift+9 switches to.";
                  };

                  native = lib.mkOption {
                    type = lib.types.str;
                    example = "2560x1440@240";
                    description = "Mode Mod+Shift+0 switches back to.";
                  };
                };
              }
            );
            default = null;
            description = "Stretched 4:3 on one output, scaled to the full panel.";
          };
        };
      };
    };
  };

  # niri-flake is imported for every host (flake.nix), and its Home Manager
  # module defaults programs.niri.package to the make-niri build, which needs
  # the libdisplay-info alias even when niri is off.
  config = lib.mkMerge [
    {
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
      ];
    }

    (lib.mkIf cfg.enable {
      nixpkgs.overlays = [ inputs.niri.overlays.niri ];

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
          # The GNOME portal comes from niri-flake's module (it goes with the
          # xdp-gnome-screencast feature); listing it again doubled its D-Bus
          # service files.
          extraPortals = with pkgs; [
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
                # niri-flake's settings schema has no `scaling-mode`, `recent-windows` or
                # `recent-windows-close`, and niri doesn't merge duplicate sections, so
                # append them to the rendered nodes.
                config =
                  let
                    inherit (inputs.niri.lib) kdl;

                    extraOutputNodes = lib.optionalAttrs (cfg.stretch != null) {
                      ${cfg.stretch.output} = [ (kdl.leaf "scaling-mode" "full") ];
                    };
                    # The Alt-Tab switcher closes on the overview's spring.
                    extraAnimationNodes = [
                      (kdl.plain "recent-windows-close" [
                        (kdl.leaf "spring" decoration.animations.overview-open-close.kind.spring)
                      ])
                    ];
                    addExtra =
                      node:
                      if node.name == "output" then
                        node // { children = node.children ++ extraOutputNodes.${lib.head node.arguments} or [ ]; }
                      else if node.name == "animations" then
                        node // { children = node.children ++ extraAnimationNodes; }
                      else
                        node;

                    # Its highlight defaults to a flat gray. Urgent windows stay
                    # base03, as on the borders; the corners match the bar.
                    recentWindows = kdl.plain "recent-windows" [
                      (kdl.plain "highlight" [
                        (kdl.leaf "active-color" accent)
                        (kdl.leaf "urgent-color" colors.base03)
                        (kdl.leaf "corner-radius" 4.0)
                      ])
                    ];
                  in
                  map addExtra (lib.remove null (lib.flatten options.programs.niri.config.default))
                  ++ [ recentWindows ];

                settings =
                  let
                    rules = import ./rules.nix;
                  in
                  {
                    input = import ./input.nix;
                    inherit (cfg) outputs;
                    layout = import ./layout.nix { inherit colors accent; };
                    inherit (decoration) prefer-no-csd animations;
                    inherit (rules) window-rules layer-rules;
                    spawn-at-startup = import ./startup.nix;
                    binds =
                      import ./binds.nix
                      // lib.optionalAttrs (cfg.stretch != null) {
                        "Mod+Shift+9".action.spawn = [ "niri" "msg" "output" cfg.stretch.output "custom-mode" cfg.stretch.mode ];
                        "Mod+Shift+0".action.spawn = [ "niri" "msg" "output" cfg.stretch.output "mode" cfg.stretch.native ];
                      };

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
    })
  ];
}
