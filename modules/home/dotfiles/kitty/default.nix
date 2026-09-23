{ config, lib, username, ... }:

let
  cfg = config.modules.home.kitty;
in
{
  options = {
    modules = {
      home = {
        kitty = {
          enable = lib.mkEnableOption "kitty terminal";
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    home-manager = {
      users = {
        ${username} = {
          programs = {
            kitty = {
              enable = true;
              enableGitIntegration = true;
              shellIntegration = {
                enableFishIntegration = true;
              };

              settings = {
                force_ltr = true;
                mouse_hide_wait = 3;
                open_url_with = "firefox";
                detect_urls = true;
                copy_on_select = true;
                hide_window_decorations = true;
                confirm_os_window_close = 0;
                tab_bar_edge = "bottom";
                allow_hyperlinks = true;
                enable_audio_bell = false;
              };
            };
          };
        };
      };
    };
  };
}
