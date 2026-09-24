{ config, lib, pkgs, inputs, username, ... }:

let
  cfg = config.modules.home.stylix;
  inherit (cfg) accent;

  hmConfig = config.home-manager.users.${username};
  inherit (hmConfig.stylix) fonts;
  inherit (hmConfig.lib.stylix) colors;

  # For stylix.targets.<target>.colors.override: paints the slots a target
  # uses as its accent in the accent's color, in every form a target reads
  # (base0D, base0D-hex, base0D-rgb-r, …, the mnemonic blue, and the same
  # under withHashtag). The palette itself, so terminals and syntax, stays
  # true.
  accentFor =
    slots:
    let
      mnemonic = {
        base08 = "red";
        base09 = "orange";
        base0A = "yellow";
        base0B = "green";
        base0C = "cyan";
        base0D = "blue";
        base0E = "magenta";
        base0F = "brown";
      };
      remapSlot =
        set: slot:
        lib.mapAttrs' (name: _: lib.nameValuePair name set.${accent + lib.removePrefix slot name}) (
          lib.filterAttrs (name: _: lib.hasPrefix slot name) set
        )
        // lib.optionalAttrs (mnemonic ? ${slot}) {
          ${mnemonic.${slot}} = set.${accent};
        };
      remap = set: lib.mergeAttrsList (map (remapSlot set) slots);
    in
    remap colors
    // {
      withHashtag = remap colors.withHashtag;
    };

  # Kvantum's selection highlight is base0E; focus and pressed frames and
  # links are base0D.
  qtOverride = accentFor [
    "base0D"
    "base0E"
  ];

  # Stylix's Kvantum theme puts the window on base01 and palette(light) on
  # base03, while its GTK theme has windows on base00 and cards on base01: Qt
  # apps came out darker, and KeePassXC's unlock card (palette(light)) a
  # bright gray. Same SVG and colors, with the palette of the GTK theme.
  kvantumGtk =
    let
      name = "Base16KvantumGtk";
      qtColors = lib.recursiveUpdate colors qtOverride;
      render =
        template: extension:
        qtColors {
          # A string is taken as the template text, not its path.
          template = builtins.readFile "${inputs.stylix}/modules/qt/${template}";
          inherit extension;
        };
    in
    pkgs.runCommandLocal "base16-kvantum-gtk" { } ''
      directory="$out/share/Kvantum/${name}"
      mkdir --parents "$directory"
      sed \
        -e 's/^window\.color=.*/window.color=${colors.withHashtag.base00}/' \
        -e 's/^light\.color=.*/light.color=${colors.withHashtag.base01}/' \
        -e 's/^mid\.light\.color=.*/mid.light.color=${colors.withHashtag.base01}/' \
        ${render "kvconfig.mustache" ".kvconfig"} > "$directory/${name}.kvconfig"
      cp ${render "kvantum.svg.mustache" ".svg"} "$directory/${name}.svg"
    '';
in
{
  options = {
    modules = {
      home = {
        stylix = {
          enable = lib.mkEnableOption "stylix theme (catppuccin mocha, peach accent)";

          # A slot rather than a color: modules read whichever form they need
          # (colors.${accent}, colors.withHashtag.${accent}, …), and it keeps
          # following the scheme (Peach is base09 in every Catppuccin flavor).
          accent = lib.mkOption {
            type = lib.types.strMatching "base0[0-9A-F]";
            default = "base09";
            readOnly = true;
            description = "Base16 slot of the accent color (Catppuccin Peach), for modules that paint accent roles themselves.";
          };
        };
      };
    };
  };

  config = lib.mkMerge [
    {
      # Imported even while disabled, since other modules set
      # stylix.targets.*. niri-flake adds its stylix target by itself only
      # next to stylix's NixOS module.
      home-manager = {
        sharedModules = [
          inputs.stylix.homeModules.stylix
          inputs.niri.homeModules.stylix
          {
            stylix = {
              # Home Manager can't set overlays under useGlobalPkgs, and the
              # gtksourceview and nixos-icons ones would rebuild those
              # packages and everything that depends on them.
              overlays = {
                enable = false;
              };
            };
          }
        ];
      };
    }

    (lib.mkIf cfg.enable {
      # What stylix's font-packages and fontconfig NixOS targets did, from
      # the Home Manager config: the fonts in /etc/fonts, which sandboxed apps
      # (Yandex Browser) mirror instead of the user's fontconfig. No console
      # palette: the TTY, boot log and ly keep their stock colors.
      fonts = {
        inherit (fonts) packages;
        fontconfig = {
          defaultFonts = lib.genAttrs [
            "monospace"
            "serif"
            "sansSerif"
            "emoji"
          ] (family: [ fonts.${family}.name ]);
        };
      };

      home-manager = {
        users = {
          ${username} = {
            stylix = {
              enable = true;
              polarity = "dark";
              # Stylix's own pinned scheme repo: a flake input, so no IFD.
              base16Scheme = "${inputs.stylix.inputs.tinted-schemes}/base16/catppuccin-mocha.yaml";
              # The palette stays true: base0D is ANSI blue in terminals and
              # functions in syntax themes. The UI targets below paint their
              # own accent slot with the accent instead.
              # No stylix.image: the scheme is explicit and Noctalia owns the
              # wallpaper (~/pictures/wallpapers).

              # Only the targets below: with autoEnable every other target
              # writes files for apps that aren't installed (blender, vencord,
              # gedit, …).
              autoEnable = false;

              fonts = {
                sansSerif = {
                  package = pkgs.inter;
                  name = "Inter";
                };
                # Nerd Font glyphs for eza/starship/yazi icons; the Mono variant
                # keeps icons single-cell for terminals, ligatures stay (NL
                # drops them).
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
                gtk = {
                  enable = true;
                  flatpakSupport = {
                    enable = false;
                  };
                  # Only the accent: a base0D override would also turn GTK's
                  # named blue_1…blue_5 palette colors peach.
                  extraCss = ''
                    @define-color accent_color ${colors.withHashtag.${accent}};
                    @define-color accent_bg_color ${colors.withHashtag.${accent}};
                  '';
                };
                # qt5ct/qt6ct + Kvantum for KeePassXC, Telegram and
                # MControlCenter, exported through the session's environment.d.
                qt = {
                  enable = true;
                  # File dialogs via xdg-desktop-portal-gtk, as with the old
                  # gtk3 platform theme.
                  standardDialogs = "xdgdesktopportal";
                  colors = {
                    override = qtOverride;
                  };
                };
                # XWayland cursor and Xresources palette.
                x11 = {
                  enable = true;
                };

                # niri-flake's module: border colors and cursor. It has no
                # colors.override; modules.home.niri sets the active border.
                niri = {
                  enable = true;
                };
                # Custom "stylix" palette (bar, launcher, lock screen), dark
                # mode, font and opacity. mPrimary is base0D; so is the
                # palette's terminal blue, which only Noctalia's templates
                # read, and those are off.
                noctalia = {
                  enable = true;
                  colors = {
                    override = accentFor [ "base0D" ];
                  };
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
                  # Firefox Color's tab line, focus and highlight colors, and
                  # reader mode's links, are base0D.
                  colors = {
                    override = accentFor [ "base0D" ];
                  };
                };
                # Its base0D is also syntax (functions), so modules.home.zed
                # overrides only the UI colors.
                zed = {
                  enable = true;
                };
                # Theme and color.ini; modules.home.spotify remaps the roles to
                # the accent and adds the font.
                spicetify = {
                  enable = true;
                };
                obsidian = {
                  enable = true;
                  # Obsidian's accent is base0E; no vaults exist yet, list
                  # them in vaultNames to theme them.
                  colors = {
                    override = accentFor [ "base0E" ];
                  };
                };
                # ReColor add-on in programs.anki.addons, which
                # modules.home.anki installs without programs.anki itself.
                # Accent, primary buttons, focus and links are base0D (so is
                # the new-card count).
                anki = {
                  enable = true;
                  colors = {
                    override = accentFor [ "base0D" ];
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
                # bat, fzf.fish previews and man pages; delta keeps its own
                # base16 syntax theme on the terminal palette.
                bat = {
                  enable = true;
                };
                yazi = {
                  enable = true;
                };
                # LS_COLORS for eza, fd and ls.
                vivid = {
                  enable = true;
                };
                # Also enables the theme in Vencord's settings.json, which Home
                # Manager then owns: plugins are declared in Nix too.
                # Discord's brand colors: base0D (buttons, checkboxes,
                # brand-260/360), base0F (brand-500) and base07 (brand text).
                vesktop = {
                  enable = true;
                  colors = {
                    override = accentFor [
                      "base0D"
                      "base0F"
                      "base07"
                    ];
                  };
                };
                # Also adds a top-level ui.skin that k9s rejects;
                # modules.home.k9s forces its settings.
                k9s = {
                  enable = true;
                };
                kubecolor = {
                  enable = true;
                };
                # modules.home.opencode paints the accent roles.
                opencode = {
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

            qt = {
              kvantum = {
                themes = [ kvantumGtk ];
                settings = {
                  General = {
                    theme = lib.mkForce "Base16KvantumGtk";
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
  ];
}
