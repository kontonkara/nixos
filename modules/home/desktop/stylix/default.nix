{
  config,
  inputs,
  lib,
  pkgs,
  username,
  ...
}:

let
  cfg = config.modules.home.stylix;
in
{
  options.modules.home.stylix.enable = lib.mkEnableOption "shared Stylix application palette";

  config = lib.mkIf cfg.enable {
    home-manager.users.${username} = {
      imports = [
        inputs.stylix.homeModules.stylix

        (
          { config, ... }:
          let
            peach = config.lib.stylix.colors.withHashtag.base09;
          in
          {
            # FZF uses base0C/base0D for generic pointer and highlight roles.
            # Derive both from the palette's Peach slot without changing the
            # semantic Base16 mapping used by other applications.
            stylix.targets.fzf.colors.override.withHashtag = {
              base0C = peach;
              base0D = peach;
            };
          }
        )
      ];

      stylix = {
        enable = true;
        autoEnable = false;
        polarity = "dark";
        base16Scheme = "${pkgs.base16-schemes}/share/themes/catppuccin-mocha.yaml";

        targets = {
          bat.enable = true;
          fzf.enable = true;
          starship.enable = true;

          # Plasma and Qt are owned by the generated native KDE color scheme.
          kde.enable = false;
          qt.enable = false;

          # Keep current application-native appearance and font choices.
          firefox.enable = false;
          fish.enable = false;
          gtk.enable = false;
          vscode.enable = false;
        };
      };

      # Starship's generic navigation/repository accents use the palette's
      # Peach slot; success and failure indicators remain semantic green/red.
      programs.starship.settings = {
        directory.style = "bold base09";
        git_branch.style = "bold base09";
      };
    };
  };
}
