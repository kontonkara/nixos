{ config, lib, inputs, username, ... }:

let
  cfg = config.modules.home.mimo-code;
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
                };
              };
            };
          };
        };
      };
    };
  };
}
