{
  prefer-no-csd = true;

  animations =
    let
      # Critically damped (near 1.0): no overshoot, buttery settle.
      # Slightly softer stiffness than before, epsilon small enough that
      # 240 Hz eDP keeps drawing micro-corrections instead of snapping.
      # Kept in sync across horizontal-view-movement / window-movement /
      # window-resize so related motion feels like one animation.
      smooth-spring = {
        spring = {
          damping-ratio = 0.95;
          stiffness = 500;
          epsilon = 0.00005;
        };
      };

      # Same family as smooth-spring, a touch looser for full-workspace pans.
      switch-spring = {
        spring = {
          damping-ratio = 0.95;
          stiffness = 480;
          epsilon = 0.00005;
        };
      };

      # CSS cubic-bezier(0.16, 1, 0.3, 1) — long smooth tail (easeOutExpo-like).
      # 280ms: one notch slower than before, reads as glide rather than snap.
      open-out = {
        easing = {
          duration-ms = 280;
          curve = "cubic-bezier";
          curve-args = [
            0.16
            1.0
            0.3
            1.0
          ];
        };
      };

      # Decelerate out instead of accelerating: closing dissolves, not smacks.
      # CSS cubic-bezier(0.3, 0, 0.2, 1).
      close-in = {
        easing = {
          duration-ms = 200;
          curve = "cubic-bezier";
          curve-args = [
            0.3
            0.0
            0.2
            1.0
          ];
        };
      };

      # Quick but not abrupt overlay pop, CSS cubic-bezier(0.16, 1, 0.3, 1).
      overlay-in = {
        easing = {
          duration-ms = 220;
          curve = "cubic-bezier";
          curve-args = [
            0.16
            1.0
            0.3
            1.0
          ];
        };
      };
    in
    {
      workspace-switch = {
        kind = switch-spring;
      };

      window-open = {
        kind = open-out;
      };

      window-close = {
        kind = close-in;
      };

      horizontal-view-movement = {
        kind = smooth-spring;
      };

      window-movement = {
        kind = smooth-spring;
      };

      window-resize = {
        kind = smooth-spring;
      };

      overview-open-close = {
        kind = switch-spring;
      };

      screenshot-ui-open = {
        kind = overlay-in;
      };

      config-notification-open-close = {
        kind = overlay-in;
      };

      exit-confirmation-open-close = {
        kind = overlay-in;
      };
    };
}
