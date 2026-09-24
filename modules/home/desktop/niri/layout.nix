{
  gaps = 16;

  center-focused-column = "never";

  preset-column-widths = [
    { proportion = 1.0 / 3.0; }
    { proportion = 0.5; }
    { proportion = 2.0 / 3.0; }
  ];

  default-column-width.proportion = 1.0;

  focus-ring = {
    enable = false;
    width = 4;
    active.color = "#7fc8ff";
    inactive.color = "#505050";
  };

  # The inactive color (and the cursor) come from niri-flake's stylix
  # module (base03); default.nix sets the active one to the accent.
  border = {
    enable = true;
    width = 3;
    urgent.color = "#9b0000";
  };

  shadow = {
    enable = true;
    softness = 30;
    spread = 5;
    offset = {
      x = 0;
      y = 5;
    };
    color = "#00000070";
  };
}
