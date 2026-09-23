{ config, lib, ... }:

let
  cfg = config.modules.system.services.ly;
in
{
  options = {
    modules = {
      system = {
        services = {
          ly = {
            enable = lib.mkEnableOption "ly tui display manager";
          };
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    services = {
      displayManager = {
        ly = {
          enable = true;
          x11Support = false;
          settings = {
            setup_cmd = "";
            default_session = "niri.desktop";
            hide_borders = true;
            blank_box = false;
            text_in_center = false;
            box_title = "null";
            initial_info_text = "null";
            hide_version_string = true;
            hide_key_hints = true;
            clear_password = true;
            allow_empty_password = false;
            auth_fails = 3;
            default_input = "password";
            input_len = 69;
            save = true;
            load = true;
            session_log = "null";
            numlock = true;
            clock = "%B, %A %d @ %H:%M:%S";
            bigclock = "en";
            lang = "en";
            margin_box_h = 0;
            margin_box_v = 0;
            min_refresh_delta = 100;
          };
        };
      };
    };
  };
}
