{ config, lib, pkgs, inputs, username, ... }:

let
  cfg = config.modules.home.pi;

  llm = config.modules.system.services.freetoken;
  server = llm.settings;

  searxng = config.modules.system.services.searxng;

  # Pi has no MCP, so web search is a skill around a script.
  webSearch = pkgs.writeShellApplication {
    name = "web-search";
    runtimeInputs = [
      pkgs.curl
      pkgs.jq
      pkgs.w3m
    ];
    text = ''
      case "''${1:-}" in
        search)
          shift
          curl -sfG "${searxng.url}/search" --data-urlencode "q=$*" --data format=json \
            | jq -r '.results[:10][] | "\(.title)\n\(.url)\n\(.content // "")\n"'
          ;;
        fetch)
          w3m -dump -cols 120 "$2" | head -n 400
          ;;
        *)
          echo "usage: web-search search <query> | web-search fetch <url>" >&2
          exit 1
          ;;
      esac
    '';
  };
in
{
  options = {
    modules = {
      home = {
        pi = {
          enable = lib.mkEnableOption "pi coding agent";
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    home-manager = {
      users = {
        ${username} = {
          programs = {
            pi-coding-agent = {
              enable = true;
              package = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.pi;

              # Global AGENTS.md, shared with qwen.
              context = ../agent-context.md;

              # settings.json and models.json become read-only store links;
              # pi only writes settings.json on an explicit save (ctrl+s).
              settings = {
                enableInstallTelemetry = false;
              }
              // lib.optionalAttrs llm.enable {
                defaultProvider = "freetoken";
                defaultModel = llm.default;
              };

              # The server is a plain OpenAI-compatible endpoint serving
              # whichever freetoken-<name> unit runs, so /model in pi only
              # relabels the session: the running unit decides what answers.
              models = lib.mkIf llm.enable {
                providers = {
                  freetoken = {
                    baseUrl = "http://${server.host}:${toString server.port}/v1";
                    api = "openai-completions";
                    apiKey = "local";
                    models = lib.mapAttrsToList (name: _: {
                        id = name;
                        reasoning = true;
                        contextWindow = server.num-tokens;
                        maxTokens = 16384;
                        # Ornith's template only knows enable_thinking, which
                        # this sends (off really turns thinking off); every
                        # other level just thinks, FreeToken has no budget.
                        compat = {
                          thinkingFormat = "qwen-chat-template";
                        };
                      }) llm.models;
                  };
                };
              };
            };
          };

          home = {
            sessionVariables = {
              # A store binary can't update; this stops the pi.dev request
              # and the toast about the version nix pins.
              PI_SKIP_VERSION_CHECK = "1";
            };

            file = lib.mkIf searxng.enable {
              ".pi/agent/skills/web-search/SKILL.md" = {
                text = ''
                  ---
                  name: web-search
                  description: Search the web and read web pages. Use when the task needs current information, documentation, release notes, error messages or anything outside the local files.
                  ---

                  Search through the local SearXNG (it runs while the model server runs):

                  ```sh
                  ${lib.getExe webSearch} search <query>
                  ```

                  It prints the top 10 results as title, URL and snippet. Read a page as plain text (first 400 lines):

                  ```sh
                  ${lib.getExe webSearch} fetch <url>
                  ```

                  Search first, then fetch the one or two most relevant pages instead of guessing from snippets. Prefer official documentation and source repositories.
                '';
              };
            };
          };
        };
      };
    };
  };
}
