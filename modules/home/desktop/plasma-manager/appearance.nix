{
  config,
  pkgs,
  ...
}:

let
  fonts = config.stylix.fonts;
  cursor = config.stylix.cursor;

  iconThemePackage = pkgs.catppuccin-papirus-folders.override {
    flavor = "mocha";
    accent = "peach";
  };
in
{
  home.packages = [
    cursor.package
    iconThemePackage
  ];

  programs.plasma = {
    workspace = {
      colorScheme = "CatppuccinMochaPeach";

      cursor = {
        theme = cursor.name;
        size = cursor.size;
      };

      iconTheme = "Papirus-Dark";
    };

    fonts = {
      general = {
        family = fonts.sansSerif.name;
        pointSize = fonts.sizes.applications;
      };

      fixedWidth = {
        family = fonts.monospace.name;
        pointSize = fonts.sizes.terminal;
      };

      small = {
        family = fonts.sansSerif.name;
        pointSize = fonts.sizes.desktop;
      };

      toolbar = {
        family = fonts.sansSerif.name;
        pointSize = fonts.sizes.desktop;
      };

      menu = {
        family = fonts.sansSerif.name;
        pointSize = fonts.sizes.desktop;
      };

      windowTitle = {
        family = fonts.sansSerif.name;
        pointSize = fonts.sizes.desktop;
      };
    };
  };
}
