{ config, lib, username, ... }:

let
  cfg = config.modules.home.vesktop;
in
{
  options = {
    modules = {
      home = {
        vesktop = {
          enable = lib.mkEnableOption "vesktop discord client";
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    home-manager = {
      users = {
        ${username} = {
          programs = {
            vesktop = {
              enable = true;

              # Vencord's settings.json is written here (read-only, stylix
              # adds its theme), so plugins are picked here, not in the app.
              vencord = {
                settings = {
                  plugins =
                    lib.genAttrs [
                      "ClearURLs"
                      "ImageZoom"
                      "MessageClickActions"
                      "CallTimer"
                      "VolumeBooster"
                      "WhoReacted"
                      "FavoriteEmojiFirst"
                      "PlatformIndicators"
                    ] (_plugin: { enabled = true; })
                    // {
                      Translate = {
                        enabled = true;
                        # Received messages into Russian; what you send
                        # still goes out in English (its default).
                        receivedOutput = "ru";
                      };
                    };
                };
              };
            };
          };
        };
      };
    };
  };
}
