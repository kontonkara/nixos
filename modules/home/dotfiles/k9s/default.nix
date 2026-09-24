{ config, lib, username, ... }:

let
  cfg = config.modules.home.k9s;
in
{
  options = {
    modules = {
      home = {
        k9s = {
          enable = lib.mkEnableOption "k9s kubernetes tui";
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    home-manager = {
      users = {
        ${username} = {
          programs = {
            k9s = {
              enable = true;

              # Forced to drop the top-level `ui.skin` stylix's k9s target adds,
              # which k9s's schema rejects on every start; Home Manager still
              # sets k9s.ui.skin to the only skin. No refreshRate: the 2s
              # default is also the floor k9s caps to.
              settings = lib.mkForce {
                k9s = {
                  # Nix pins the version; this only polls GitHub for an
                  # upgrade notice.
                  skipLatestRevCheck = true;
                  logger = {
                    # 100 by default; the view buffers up to 5000 lines.
                    tail = 500;
                    textWrap = true;
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
