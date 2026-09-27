# accentRgb: modules.home.stylix.accent as GLSL vec3 components ("r, g, b").
{ accentRgb }:

{
  prefer-no-csd = true;

  # The shaders cost no extra pass: niri renders an opening or closing window
  # offscreen either way, and they add one texture read per pixel.
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

      # easeOutBack, CSS cubic-bezier(0.34, 1.2, 0.64, 1): a new window grows
      # a hair past its size and settles back, a small pop. window-open.glsl
      # takes the unclamped progress for the scale (opacity stays clamped).
      open-out = {
        easing = {
          duration-ms = 280;
          curve = "cubic-bezier";
          curve-args = [
            0.34
            1.2
            0.64
            1.0
          ];
        };
      };

      # Linear: the burn front sweeps the noise at an even pace, and the
      # noise itself is densest mid-range, so it starts and ends softly.
      burn = {
        easing = {
          duration-ms = 300;
          curve = "linear";
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
        custom-shader = builtins.readFile ./shaders/window-open.glsl;
      };

      window-close = {
        kind = burn;
        custom-shader = builtins.replaceStrings [ "@accent@" ] [ accentRgb ] (
          builtins.readFile ./shaders/window-close.glsl
        );
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
