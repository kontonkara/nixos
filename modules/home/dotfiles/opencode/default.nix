{ config, lib, inputs, username, ... }:

let
  cfg = config.modules.home.opencode;

  hmConfig = config.home-manager.users.${username};
  hmStylix = hmConfig.stylix;
  accent = hmConfig.lib.stylix.colors.withHashtag.${config.modules.home.stylix.accent};
in
{
  options = {
    modules = {
      home = {
        opencode = {
          enable = lib.mkEnableOption "opencode coding agent";
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    home-manager = {
      users = {
        ${username} = {
          programs = {
            opencode = {
              enable = true;
              # Upstream's release binary, bumped with the other llm-agents
              # tools rather than rebuilt from source like nixpkgs' opencode.
              package = inputs.llm-agents.packages.x86_64-linux.opencode;

              settings = {
                # It can't replace a store binary: every start would only
                # probe npm/bun/brew and toast about versions nix pins.
                autoupdate = false;
              };

              # Stylix's theme takes accent from base0F, primary from base0D
              # (which is also syntax functions and Markdown links) and
              # borderActive from base03; only these UI roles get the accent.
              themes = lib.mkIf (hmStylix.enable && hmStylix.targets.opencode.enable) {
                stylix = {
                  theme = lib.genAttrs [
                    "accent"
                    "borderActive"
                    "primary"
                  ] (_: lib.mkForce {
                    dark = accent;
                    light = accent;
                  });
                };
              };
            };
          };
        };
      };
    };
  };
}
