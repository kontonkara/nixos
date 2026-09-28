# The built-in 17" panel (MNH301CA3-1, 2560x1440 at 240 Hz).
{
  modules = {
    home = {
      niri = {
        outputs = {
          "eDP-1" = {
            scale = 1.0;
            mode = {
              width = 2560;
              height = 1440;
              refresh = 240.0;
            };
            position = {
              x = 0;
              y = 0;
            };
            variable-refresh-rate = true;
          };
        };

        # 4:3 stretched to the full panel, and back.
        stretch = {
          output = "eDP-1";
          mode = "1440x1080@240";
          native = "2560x1440@240";
        };
      };
    };
  };
}
