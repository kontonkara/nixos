{ config, lib, username, ... }:

let
  cfg = config.modules.home.tealdeer;
in
{
  options = {
    modules = {
      home = {
        tealdeer = {
          enable = lib.mkEnableOption "tealdeer tldr client";
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    home-manager = {
      users = {
        ${username} = {
          programs = {
            # HM's weekly tldr-update timer is on by default.
            tealdeer = {
              enable = true;

              settings = {
                display = {
                  compact = true;
                  use_pager = true;
                };

                # The timer's first run is next Monday (Persistent= doesn't
                # fire for a timer that never ran); this downloads the cache
                # on first use instead of failing with "cache not found".
                updates = {
                  auto_update = true;
                };
              };
            };
          };
        };
      };
    };
  };
}
