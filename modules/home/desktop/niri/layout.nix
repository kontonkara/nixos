# colors: stylix's palette (withHashtag); accent: modules.home.stylix.accent.
{ colors, accent }:

{
  gaps = 16;

  # Shown for the ~0.5 s between niri's first frame and Noctalia's wallpaper
  # (Noctalia fades it in from here); niri's default is a flat gray.
  background-color = colors.base00;

  center-focused-column = "never";

  preset-column-widths = [
    { proportion = 1.0 / 3.0; }
    { proportion = 0.5; }
    { proportion = 2.0 / 3.0; }
  ];

  default-column-width.proportion = 1.0;

  # Urgent windows (e.g. Telegram asking for attention) get no color of their
  # own: the same base03 as any unfocused window.
  focus-ring = {
    enable = false;
    width = 4;
    active.color = accent;
    inactive.color = colors.base03;
    urgent.color = colors.base03;
  };

  border = {
    enable = true;
    width = 3;
    active.color = accent;
    inactive.color = colors.base03;
    urgent.color = colors.base03;
  };

  # The focused window casts a deeper shadow than the rest: depth without
  # extra passes, every window already has one.
  shadow = {
    enable = true;
    softness = 30;
    spread = 5;
    offset = {
      x = 0;
      y = 5;
    };
    color = "${colors.base00}70";
    inactive-color = "${colors.base00}38";
  };

  # Where a dragged window will land; niri's default is a light blue.
  insert-hint = {
    display = {
      color = "${accent}80";
    };
  };
}
