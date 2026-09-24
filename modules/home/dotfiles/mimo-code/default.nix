{ config, lib, inputs, username, ... }:

let
  cfg = config.modules.home.mimo-code;

  hmConfig = config.home-manager.users.${username};
  hmStylix = hmConfig.stylix;
in
{
  options = {
    modules = {
      home = {
        mimo-code = {
          enable = lib.mkEnableOption "mimo-code coding agent";
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    home-manager = {
      users = {
        ${username} = {
          home = {
            packages = [
              inputs.llm-agents.packages.x86_64-linux.mimo-code
            ];
          };

          # config.json is the lowest-priority global file, below mimocode.json
          # and mimocode.jsonc. The existing mimocode.jsonc stays writable:
          # settings the app saves go to the first of mimocode.jsonc,
          # mimocode.json and config.json that exists, and its plugin install
          # keeps package.json and node_modules in this directory.
          xdg = {
            configFile = {
              "mimocode/config.json" = {
                text = builtins.toJSON {
                  "$schema" = "https://mimo.xiaomi.com/mimocode/config.json";
                  # Like opencode, it can't replace a store binary; this only
                  # stops the toast about versions nix pins (the npm/bun probe
                  # and version check run regardless).
                  autoupdate = false;
                  # Its build agent has a fixed orange (#fb8147) for the prompt
                  # bar and agent label; primary is the theme's accent.
                  agent = {
                    build = {
                      color = "primary";
                    };
                  };
                };
              };

              # Stylix only themes opencode. mimo reads the same theme format
              # from themes/*.json and the theme name from tui.json, so this is
              # opencode's "stylix" theme, accent roles included
              # (modules.home.opencode). Both need mimo's $schema: it rewrites
              # a missing or opencode one in place.
              "mimocode/themes/stylix.json" = lib.mkIf (hmStylix.enable && hmStylix.targets.opencode.enable) {
                text = builtins.toJSON (
                  hmConfig.programs.opencode.themes.stylix
                  // {
                    "$schema" = "https://mimo.xiaomi.com/mimocode/theme.json";
                  }
                );
              };
              "mimocode/tui.json" = lib.mkIf (hmStylix.enable && hmStylix.targets.opencode.enable) {
                text = builtins.toJSON {
                  "$schema" = "https://mimo.xiaomi.com/mimocode/tui.json";
                  theme = "stylix";
                };
              };
            };
          };
        };
      };
    };
  };
}
