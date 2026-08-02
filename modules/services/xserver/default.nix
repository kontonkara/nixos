{ ... }:

{
  services = {
    xserver = {
      enable = true;
      xkb = {
        layout = "us,ru";
        options = "grp:alt_shift_toggle";
      };
      videoDrivers = [
        "nvidia"
      ];
    };
  };
}
