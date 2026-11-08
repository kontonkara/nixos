{
  window-rules = [
    {
      matches = [ ];
      geometry-corner-radius = {
        bottom-left = 8.0;
        bottom-right = 8.0;
        top-left = 8.0;
        top-right = 8.0;
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
        { app-id = "^yandex-browser$"; }
      ];
      block-out-from = "screencast";
    }

    # Steam's toasts open as regular windows; float them into the corner
    # (niri wiki, Application Issues).
    {
      matches = [ {
        app-id = "steam";
        title = "^notificationtoasts_\\d+_desktop$";
      } ];
      default-floating-position = {
        x = 10;
        y = 10;
        relative-to = "bottom-right";
      };
    }
  ];
}
