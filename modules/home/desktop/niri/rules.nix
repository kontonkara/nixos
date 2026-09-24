{
  window-rules = [
    {
      matches = [ ];
      geometry-corner-radius = {
        bottom-left = 2.0;
        bottom-right = 2.0;
        top-left = 2.0;
        top-right = 2.0;
      };
      clip-to-geometry = true;
    }

    # Open the Firefox picture-in-picture player as floating by default.
    {
      matches = [ {
        app-id = "firefox$";
        title = "^Picture-in-Picture$";
      } ];
      open-floating = true;
    }

    # Black out secrets in portal screencasts (calls, OBS, browser sharing).
    # Not "screen-capture": Sunshine uses wlr-screencopy, and these windows
    # must stay usable when streaming to Moonlight.
    {
      matches = [
        { app-id = "^org\\.keepassxc\\.KeePassXC$"; }
        { app-id = "^org\\.telegram\\.desktop$"; }
      ];
      block-out-from = "screencast";
    }
  ];

  layer-rules = [
    {
      matches = [ { namespace = "^swww-daemon$"; } ];
      place-within-backdrop = true;
    }
  ];
}
