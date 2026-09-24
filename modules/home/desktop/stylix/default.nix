{ config, lib, pkgs, inputs, username, ... }:

let
  cfg = config.modules.home.stylix;

  # Catppuccin Mocha with Peach in base0D, the slot most targets use as
  # their accent (borders, selection, links, Noctalia's primary).
  accent = "fab387";

  inherit (config.stylix) fonts;
in
{
  options = {
    modules = {
      home = {
        stylix = {
          enable = lib.mkEnableOption "stylix theme (catppuccin mocha, peach accent)";
        };
      };
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      # System level so fontconfig, the Qt environment and the console follow
      # the palette too; stylix copies these settings into Home Manager and
      # niri-flake adds its niri target there.
      stylix = {
        enable = true;
        polarity = "dark";
        # Stylix's own pinned scheme repo: a flake input, so no IFD.
        base16Scheme = "${inputs.stylix.inputs.tinted-schemes}/base16/catppuccin-mocha.yaml";
        override = {
          base0D = accent;
        };
        # No stylix.image: the scheme is explicit and Noctalia owns the
        # wallpaper (~/pictures/wallpapers).

        # The gtksourceview and nixos-icons overlays would rebuild those
        # packages and everything that depends on them.
        overlays = {
          enable = false;
        };

        # Only the targets below: with autoEnable every other target writes
        # files for apps that aren't installed (blender, vencord, gedit, …).
        autoEnable = false;

        fonts = {
          sansSerif = {
            package = pkgs.inter;
            name = "Inter";
          };
          # Nerd Font glyphs for eza/starship/yazi icons; the Mono variant keeps
          # icons single-cell for terminals, ligatures stay (NL drops them).
          monospace = {
            package = pkgs.nerd-fonts.jetbrains-mono;
            name = "JetBrainsMono Nerd Font Mono";
          };
          sizes = {
            applications = 11;
          };
        };

        cursor = {
          package = pkgs.bibata-cursors;
          name = "Bibata-Modern-Classic";
          size = 24;
        };

        icons = {
          enable = true;
          # Papirus with Mocha Peach folders.
          package = pkgs.catppuccin-papirus-folders.override {
            flavor = "mocha";
            accent = "peach";
          };
          dark = "Papirus-Dark";
          light = "Papirus-Light";
        };

        targets = {
          # VT palette, also used by ly.
          console = {
            enable = true;
          };
          font-packages = {
            enable = true;
          };
          fontconfig = {
            enable = true;
          };
          gtk = {
            enable = true;
          };
          # qt5ct/qt6ct + Kvantum for KeePassXC, Telegram and polkit-kde-agent.
          qt = {
            enable = true;
          };
        };
      };

      home-manager = {
        users = {
          ${username} = {
            stylix = {
              targets = {
                gtk = {
                  enable = true;
                  flatpakSupport = {
                    enable = false;
                  };
                };
                qt = {
                  enable = true;
                  # File dialogs via xdg-desktop-portal-gtk, as with the old
                  # gtk3 platform theme.
                  standardDialogs = "xdgdesktopportal";
                };
                # XWayland cursor and Xresources palette.
                x11 = {
                  enable = true;
                };

                # niri-flake's module: border colors and cursor.
                niri = {
                  enable = true;
                };
                # Custom "stylix" palette (bar, launcher, lock screen), dark
                # mode, font and opacity.
                noctalia = {
                  enable = true;
                };
                kitty = {
                  enable = true;
                };

                firefox = {
                  enable = true;
                  profileNames = [ username ];
                  colorTheme = {
                    enable = true;
                  };
                  # Families already resolve through fontconfig; this would
                  # also drop the default web font from 16px to 15px (11pt).
                  fonts = {
                    enable = false;
                  };
                };
                vscode = {
                  enable = true;
                };
                obsidian = {
                  enable = true;
                  # Obsidian's accent is base0E; no vaults exist yet, list
                  # them in vaultNames to theme them.
                  colors = {
                    override = {
                      withHashtag = {
                        base0E = "#${accent}";
                      };
                    };
                  };
                };

                fish = {
                  enable = true;
                };
                starship = {
                  enable = true;
                };
                fzf = {
                  enable = true;
                };
                yazi = {
                  enable = true;
                };
                mangohud = {
                  enable = true;
                  # Colors only: the font block shrinks the HUD from 24px to
                  # ~15px and opacity makes its background fully opaque.
                  fonts = {
                    enable = false;
                  };
                  opacity = {
                    enable = false;
                  };
                };
              };
            };

            # Firefox Color keeps its theme in extension storage, which Home
            # Manager only writes with force.
            programs = {
              firefox = {
                profiles = {
                  ${username} = {
                    extensions = {
                      settings = {
                        "FirefoxColor@mozilla.com" = {
                          force = true;
                        };
                      };
                    };
                  };
                };
              };
            };

            # Home Manager's gtk module writes font-name; stylix only sets these
            # two in its gnome target, which is GNOME Shell specific.
            dconf = {
              settings = {
                "org/gnome/desktop/interface" = {
                  monospace-font-name = "${fonts.monospace.name} ${toString fonts.sizes.applications}";
                  document-font-name = "${fonts.sansSerif.name} ${toString fonts.sizes.applications}";
                };
              };
            };
          };
        };
      };
    })

    (lib.mkIf (!cfg.enable) {
      # niri-flake imports its stylix module for every user whenever the
      # stylix NixOS module is present; it needs stylix's Home Manager options,
      # which stylix only imports while enabled.
      home-manager = {
        sharedModules = [
          inputs.stylix.homeModules.stylix
          {
            # What stylix's own integration sets under useGlobalPkgs.
            stylix = {
              overlays = {
                enable = false;
              };
            };
          }
        ];
      };
    })
  ];
}
