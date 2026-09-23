[
  # Work around WezTerm's initial configure bug.
  {
    matches = [ { app-id = "^org\\.wezfurlong\\.wezterm$"; } ];
    default-column-width = { };
  }

  # Open the Firefox picture-in-picture player as floating by default.
  {
    matches = [ {
      app-id = "firefox$";
      title = "^Picture-in-Picture$";
    } ];
    open-floating = true;
  }
]
