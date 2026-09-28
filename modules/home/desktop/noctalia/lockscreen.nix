# Lock screen widgets per monitor ([lockscreen_widgets.widget]): a large
# clock with the date under it, and the login box without session buttons.
# Positions are logical pixels, so they come from the host's niri outputs
# (mode / scale); a host without outputs keeps Noctalia's default lock screen.
{ lib, outputs }:

let
  widgetsFor =
    output: settings:
    let
      width = settings.mode.width / (settings.scale or 1.0);
      height = settings.mode.height / (settings.scale or 1.0);
      centerX = width / 2.0;
      clockY = height * 0.3;

      text = {
        background = false;
        center_text = true;
        shadow = true;
      };

      # The screen size the coordinates are for. Without it Noctalia fills it
      # in on load and saves the whole layout to settings.toml, which then
      # overrides this file.
      placement = {
        placement_width = width;
        placement_height = height;
      };
    in
    lib.mapAttrs (_: widget: widget // placement) {
      # The content is scaled to fit the box, so the box sets the size.
      "clock@${output}" = {
        type = "clock";
        inherit output;
        cx = centerX;
        cy = clockY;
        box_width = 560.0;
        box_height = 190.0;
        settings = text // {
          format = "{:%H:%M}";
          color = "on_surface";
        };
      };

      # LC_TIME is en_GB: "Sunday, 28 September". primary is the accent.
      "date@${output}" = {
        type = "clock";
        inherit output;
        cx = centerX;
        cy = clockY + 130.0;
        box_width = 560.0;
        box_height = 44.0;
        settings = text // {
          format = "{:%A, %-d %B}";
          color = "primary";
        };
      };

      # Fixed id: Noctalia drops a login box without an output and puts a
      # default one (session buttons included) in its place.
      "lockscreen-login-box@${output}" = {
        type = "login_box";
        inherit output;
        cx = centerX;
        # About where Noctalia puts it: the bottom edge 84 px above the screen's.
        cy = height - 84.0 - 110.0;
        # 0: Noctalia sizes the panel for its layout.
        box_width = 0.0;
        box_height = 0.0;
        settings = {
          layout = "regular";
          # Reboot, shutdown and logout stay in the session menu (Mod+P).
          show_session_buttons = false;
          # The bar's corners.
          background_radius = 4.0;
          input_radius = 4.0;
        };
      };
    };
in
lib.concatMapAttrs widgetsFor outputs
