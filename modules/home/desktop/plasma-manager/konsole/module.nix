{
  config,
  lib,
  ...
}:

let
  colors = config.lib.stylix.colors;
  fonts = config.stylix.fonts;

  rgb =
    color:
    let
      hex = lib.removePrefix "#" color;
      component = offset: toString (lib.fromHexString (builtins.substring offset 2 hex));
    in
    "${component 0},${component 2},${component 4}";
in
{
  programs.konsole = {
    enable = true;

    defaultProfile = "Stylix";

    profiles.Stylix = {
      colorScheme = "Stylix";

      font = {
        name = fonts.monospace.name;
        size = fonts.sizes.terminal;
      };
    };

    customColorSchemes.Stylix = {
      Background.Color = rgb colors.base00;
      BackgroundFaint.Color = rgb colors.base01;
      BackgroundIntense.Color = rgb colors.base00;

      Color0.Color = rgb colors.base00;
      Color0Faint.Color = rgb colors.base01;
      Color0Intense.Color = rgb colors.base03;

      Color1.Color = rgb colors.red;
      Color1Faint.Color = rgb colors.red;
      Color1Intense.Color = rgb colors."bright-red";

      Color2.Color = rgb colors.green;
      Color2Faint.Color = rgb colors.green;
      Color2Intense.Color = rgb colors."bright-green";

      Color3.Color = rgb colors.yellow;
      Color3Faint.Color = rgb colors.yellow;
      Color3Intense.Color = rgb colors."bright-yellow";

      Color4.Color = rgb colors.blue;
      Color4Faint.Color = rgb colors.blue;
      Color4Intense.Color = rgb colors."bright-blue";

      Color5.Color = rgb colors.magenta;
      Color5Faint.Color = rgb colors.magenta;
      Color5Intense.Color = rgb colors."bright-magenta";

      Color6.Color = rgb colors.cyan;
      Color6Faint.Color = rgb colors.cyan;
      Color6Intense.Color = rgb colors."bright-cyan";

      Color7.Color = rgb colors.base05;
      Color7Faint.Color = rgb colors.base04;
      Color7Intense.Color = rgb colors.base07;

      Foreground.Color = rgb colors.base05;
      ForegroundFaint.Color = rgb colors.base04;
      ForegroundIntense.Color = rgb colors.base07;

      General = {
        Description = "Stylix";
        Opacity = config.stylix.opacity.terminal;
        Wallpaper = "";
      };
    };
  };
}
