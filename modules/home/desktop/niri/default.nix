{ config, lib, pkgs, username, inputs, ... }:

let
  cfg = config.modules.home.niri;
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
        package = pkgs.niri-unstable;
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
        ${username} = {
          programs = {
            niri = {
              settings =
                let
                  decoration = import ./decoration.nix;
                  rules = import ./rules.nix;
                in
                {
                  input = import ./input.nix;
                  outputs = import ./outputs.nix;
                  layout = import ./layout.nix;
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
                };
            };
          };
        };
      };
    };
  };
}
