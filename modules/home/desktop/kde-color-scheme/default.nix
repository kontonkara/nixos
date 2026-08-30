{
  config,
  lib,
  username,
  ...
}:

let
  cfg = config.modules.home.kdeColorScheme;
in
{
  options.modules.home.kdeColorScheme.enable =
    lib.mkEnableOption "native KDE color scheme derived from the Stylix palette";

  config = lib.mkIf cfg.enable {
    home-manager.users.${username}.imports = [
      (
        {
          config,
          lib,
          pkgs,
          ...
        }:

        let
          colors = config.lib.stylix.colors;
          schemeId = "CatppuccinMochaPeach";

          rgb =
            color:
            let
              hex = lib.removePrefix "#" color;
              component = offset: toString (lib.fromHexString (builtins.substring offset 2 hex));
            in
            "${component 0},${component 2},${component 4}";

          normalRoles = {
            BackgroundAlternate = rgb colors.base01;
            BackgroundNormal = rgb colors.base00;
            DecorationFocus = rgb colors.base09;
            DecorationHover = rgb colors.base09;
            ForegroundActive = rgb colors.base09;
            ForegroundInactive = rgb colors.base04;
            ForegroundLink = rgb colors.base0D;
            ForegroundNegative = rgb colors.base08;
            ForegroundNeutral = rgb colors.base0A;
            ForegroundNormal = rgb colors.base05;
            ForegroundPositive = rgb colors.base0B;
            ForegroundVisited = rgb colors.base0E;
          };

          selectionRoles = normalRoles // {
            BackgroundAlternate = rgb colors.base09;
            BackgroundNormal = rgb colors.base09;

            # A single dark palette foreground keeps every selected state
            # readable against Peach, including semantic state labels.
            ForegroundActive = rgb colors.base00;
            ForegroundInactive = rgb colors.base00;
            ForegroundLink = rgb colors.base00;
            ForegroundNegative = rgb colors.base00;
            ForegroundNeutral = rgb colors.base00;
            ForegroundNormal = rgb colors.base00;
            ForegroundPositive = rgb colors.base00;
            ForegroundVisited = rgb colors.base00;
          };

          colorScheme = lib.generators.toINI { } {
            "ColorEffects:Disabled" = {
              Color = rgb colors.base03;
              ColorAmount = 0;
              ColorEffect = 0;
              ContrastAmount = 0.65;
              ContrastEffect = 1;
              IntensityAmount = 0.1;
              IntensityEffect = 2;
            };

            "ColorEffects:Inactive" = {
              ChangeSelectionColor = true;
              Color = rgb colors.base04;
              ColorAmount = 0.025;
              ColorEffect = 2;
              ContrastAmount = 0.1;
              ContrastEffect = 2;
              Enable = false;
              IntensityAmount = 0;
              IntensityEffect = 0;
            };

            "Colors:Button" = normalRoles;
            "Colors:Complementary" = normalRoles;
            "Colors:Header" = normalRoles;
            "Colors:Selection" = selectionRoles;
            "Colors:Tooltip" = normalRoles;
            "Colors:View" = normalRoles;
            "Colors:Window" = normalRoles;

            General = {
              ColorScheme = schemeId;
              Name = "Catppuccin Mocha Peach";
              shadeSortColumn = true;
            };

            KDE.contrast = 4;

            WM = {
              activeBackground = rgb colors.base01;
              activeBlend = rgb colors.base09;
              activeForeground = rgb colors.base05;
              inactiveBackground = rgb colors.base00;
              inactiveBlend = rgb colors.base03;
              inactiveForeground = rgb colors.base04;
            };
          };
        in
        {
          xdg.dataFile."color-schemes/${schemeId}.colors".text = colorScheme;
        }
      )
    ];
  };
}
