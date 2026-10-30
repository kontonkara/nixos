{ config, lib, pkgs, inputs, username, ... }:

let
  cfg = config.modules.home.qwen-code;

  llm = config.modules.system.services.freetoken;
  server = llm.settings;

  searxng = config.modules.system.services.searxng;
in
{
  options = {
    modules = {
      home = {
        qwen-code = {
          enable = lib.mkEnableOption "Qwen Code coding agent";
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
              inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.qwen-code
            ];

            file = {
              # qwen saves settings by renaming a new file over this link, so
              # what the app changes lasts until the next switch, which puts
              # the link back (force: the file in the way is the app's own).
              # Defaults change here. $version is the current settings schema:
              # without it qwen migrates the file on every start.
              ".qwen/settings.json" = {
                force = true;
                text = builtins.toJSON ({
                  "$version" = 4;
                  general = {
                    enableAutoUpdate = false;
                  };
                  privacy = {
                    usageStatisticsEnabled = false;
                  };
                  ui = {
                    autoModeAcknowledged = true;
                  };
                }
                // lib.optionalAttrs llm.enable {
                  # qwen assumes 200k for a model it doesn't know and would
                  # compress the history too late for the server's window.
                  model = {
                    generationConfig = {
                      contextWindowSize = server.num-tokens;
                    };
                  };
                }
                // lib.optionalAttrs searxng.enable {
                  # qwen's own web_search only works with Alibaba's DashScope.
                  mcpServers = {
                    searxng = {
                      command = lib.getExe pkgs.mcp-searxng;
                      env = {
                        SEARXNG_URL = searxng.url;
                      };
                    };
                  };
                });
              };

              # Global context, shared with pi. qwen's /memory writes here
              # too, like settings.json, until the next switch.
              ".qwen/QWEN.md" = {
                force = true;
                source = ../agent-context.md;
              };

              # qwen reads ~/.qwen/.env on its own, which keeps these OPENAI_*
              # variables out of every other program's environment. With all
              # three set it picks OpenAI-compatible auth without asking.
              ".qwen/.env" = lib.mkIf llm.enable {
                text = ''
                  OPENAI_API_KEY=local
                  OPENAI_BASE_URL=http://${server.host}:${toString server.port}/v1
                  OPENAI_MODEL=${llm.default}
                '';
              };
            };
          };
        };
      };
    };
  };
}
