{ config, lib, pkgs, inputs, username, ... }:

let
  cfg = config.modules.home.claude-code;

  hmConfig = config.home-manager.users.${username};
in
{
  options = {
    modules = {
      home = {
        claude-code = {
          enable = lib.mkEnableOption "Claude Code coding agent";
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    home-manager = {
      users = {
        ${username} = {
          programs = {
            claude-code = {
              enable = true;
              # Upstream's release binary, bumped with the other llm-agents
              # tools; its wrapper already turns the auto-updater off.
              package = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.claude-code;

              # settings.json becomes a read-only store link: /model, /effort
              # and /config still change the running session, but saving
              # them as defaults fails, so defaults change here. The login
              # (.credentials.json) and ~/.claude.json stay the app's.
              settings = {
                model = "opus[1m]";
                modelSettings = {
                  claude-opus-5-5 = {
                    effortLevel = "xhigh";
                  };
                };
                theme = "auto";
                autoCompactEnabled = true;
                remoteControlAtStartup = false;
                # Commits here carry no trailers: empty strings drop the
                # Co-Authored-By line and the PR footer (includeCoAuthoredBy
                # is deprecated in favour of this).
                attribution = {
                  commit = "";
                  pr = "";
                };
              };
            };
          };

          # Everything the app saved in the old file is declared above, so
          # take it over without leaving a settings.json.backup behind.
          home = {
            file = {
              "${hmConfig.programs.claude-code.configDir}/settings.json" = {
                force = true;
              };
            };
          };
        };
      };
    };
  };
}
