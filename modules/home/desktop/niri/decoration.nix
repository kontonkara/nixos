{
  prefer-no-csd = true;

  animations =
    let
      # Critically-ish damped, a bit softer than the stock stiffness=800/1000.
      # Kept in sync across horizontal-view-movement / window-movement / window-resize
      # so related motion feels like one animation (niri wiki recommendation).
      smooth-spring = {
        spring = {
          damping-ratio = 0.9;
          stiffness = 580;
          epsilon = 0.0001;
        };
      };

      # CSS cubic-bezier(0.16, 1, 0.3, 1) — long smooth tail (easeOutExpo-like).
      open-out = {
        easing = {
          duration-ms = 240;
          curve = "cubic-bezier";
          curve-args = [
            0.16
            1.0
            0.3
            1.0
          ];
        };
      };

      # Fast fade-in / settle, CSS cubic-bezier(0.4, 0, 1, 1).
      close-in = {
        easing = {
          duration-ms = 180;
          curve = "cubic-bezier";
          curve-args = [
            0.4
            0.0
            1.0
            1.0
          ];
        };
      };
    in
    {
      workspace-switch = {
        kind.spring = {
          damping-ratio = 0.88;
          stiffness = 620;
          epsilon = 0.0001;
        };
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
        kind.spring = {
          damping-ratio = 0.85;
          stiffness = 520;
          epsilon = 0.0001;
        };
      };

      screenshot-ui-open = {
        kind.easing = {
          duration-ms = 180;
          curve = "ease-out-expo";
        };
      };

      config-notification-open-close = {
        kind.spring = {
          damping-ratio = 0.8;
          stiffness = 700;
          epsilon = 0.001;
        };
      };

      exit-confirmation-open-close = {
        kind.spring = {
          damping-ratio = 0.8;
          stiffness = 450;
          epsilon = 0.01;
        };
      };
    };
}
