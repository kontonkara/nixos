{
  config,
  inputs,
  lib,
  pkgs,
  username,
  ...
}:

let
  accent = "fab387";
  cfg = config.modules.home.stylix;
in
{
  options.modules.home.stylix.enable = lib.mkEnableOption "shared Stylix application palette";

  config = lib.mkIf cfg.enable {
    home-manager = {
      users = {
        ${username} = {
          imports = [
            inputs.stylix.homeModules.stylix
          ];

          stylix = {
            enable = true;
            autoEnable = true;
            polarity = "dark";
            base16Scheme = "${pkgs.base16-schemes}/share/themes/catppuccin-mocha.yaml";
            override.base0D = accent;

            fonts = {
              monospace = {
                package = pkgs.nerd-fonts.jetbrains-mono;
                name = "JetBrainsMono Nerd Font Mono";
              };

              sansSerif = {
                package = pkgs.dejavu_fonts;
                name = "DejaVu Sans";
              };

              serif = {
                package = pkgs.dejavu_fonts;
                name = "DejaVu Serif";
              };

              emoji = {
                package = pkgs.noto-fonts-color-emoji;
                name = "Noto Color Emoji";
              };
            };

            cursor = {
              package = pkgs.bibata-cursors;
              name = "Bibata-Modern-Classic";
              size = 24;
            };

            targets = {
              # Plasma and Qt are owned by the generated native KDE color scheme
              # and plasma-manager.
              kde.enable = false;
              qt.enable = false;

              firefox.enable = false;
              fish.enable = false;
              gtk.enable = false;

              obsidian = {
                enable = true;
                colors.override.withHashtag.base0E = "#${accent}";
                vaultNames = [
                  "devops-trainee"
                  "personal"
                ];
              };
            };
          };
        };
      };
    };
  };
}
