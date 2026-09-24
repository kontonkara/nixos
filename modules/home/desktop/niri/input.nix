{
  keyboard = {
    xkb = {
      layout = "us,ru";
      options = "grp:alt_shift_toggle";
    };
    # ly turns numlock on only for the greeter; niri needs its own flag.
    numlock = true;
  };

  touchpad = {
    tap = true;
    dwt = true;
    dwtp = true;
    drag = false;
    drag-lock = false;
    natural-scroll = true;
    accel-speed = 0.2;
    accel-profile = "flat";
    scroll-method = "two-finger";
    disabled-on-external-mouse = false;
  };

  mouse = {
    natural-scroll = false;
    accel-speed = 0.4;
    accel-profile = "flat";
  };

  warp-mouse-to-focus = {
    enable = false;
  };

  focus-follows-mouse = {
    enable = true;
    max-scroll-amount = "0%";
  };
}
