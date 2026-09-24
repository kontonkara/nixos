{ config, lib, pkgs, username, ... }:

let
  cfg = config.modules.home.gtk;

  font = {
    name = "Inter";
    package = pkgs.inter;
    size = 11;
  };

  monoFont = {
    name = "JetBrains Mono";
    package = pkgs.jetbrains-mono;
    size = 11;
  };

  cursor = {
    name = "Bibata-Modern-Classic";
    package = pkgs.bibata-cursors;
    size = 24;
  };

  icons = {
    name = "Papirus-Dark";
    package = pkgs.papirus-icon-theme;
  };
in
{
  options = {
    modules = {
      home = {
        gtk = {
          enable = lib.mkEnableOption "gtk theme, font and cursor";
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    home-manager = {
      users = {
        ${username} = {
          gtk = {
            enable = true;
            inherit font;
            cursorTheme = cursor;
            colorScheme = "dark";

            iconTheme = icons;

            gtk3.extraConfig = {
              gtk-application-prefer-dark-theme = 1;
              gtk-decoration-layout = ":";
            };
            gtk4.extraConfig = {
              gtk-application-prefer-dark-theme = 1;
              gtk-decoration-layout = ":";
            };
          };

          home = {
            pointerCursor = {
              enable = true;
              inherit (cursor) name package size;
              gtk.enable = true;
              x11.enable = true;
            };

            packages = [
              font.package
              monoFont.package
            ];
          };

          fonts = {
            fontconfig = {
              enable = true;
              # Generic families resolved to DejaVu, so web pages and apps
              # without their own font (kitty included) didn't match GTK.
              defaultFonts = {
                sansSerif = [ font.name ];
                monospace = [ monoFont.name ];
                emoji = [ "Noto Color Emoji" ];
              };
            };
          };
        };
      };
    };
  };
}
