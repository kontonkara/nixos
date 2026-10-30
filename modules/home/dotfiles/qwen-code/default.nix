{ config, lib, pkgs, inputs, username, ... }:

let
  cfg = config.modules.home.qwen-code;

  llm = config.modules.system.services.freetoken;
  server = llm.settings;

  searxng = config.modules.system.services.searxng;

  # A rule in QWEN.md alone gets lost in a long session, so a hook puts the
  # reminder into the result of the second failing command in a row.
  # Commands whose non-zero exit is an answer (grep, test, ...) count as
  # neither success nor failure.
  searchNudge = pkgs.writeShellApplication {
    name = "qwen-search-nudge";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.gnugrep
      pkgs.jq
    ];
    text = ''
      input=$(cat)
      command=$(jq -r '.tool_input.command // ""' <<< "$input")
      session=$(jq -r '.session_id // "none"' <<< "$input")
      code=$(jq -r '.tool_response | tostring' <<< "$input" \
        | grep -oE 'Exit Code: [0-9]+' | tail -n 1 | grep -oE '[0-9]+' || true)

      if grep -qE '^[[:space:]]*(grep|rg|test|\[|diff|cmp|which|command|pgrep|find|ls|stat)\b' <<< "$command"; then
        exit 0
      fi

      state="''${XDG_RUNTIME_DIR:-/tmp}/qwen-search-nudge"
      mkdir -p "$state"
      count_file="$state/$session"

      if [ -z "$code" ] || [ "$code" = 0 ]; then
        rm -f "$count_file"
        exit 0
      fi

      count=$(( $(cat "$count_file" 2>/dev/null || echo 0) + 1 ))
      echo "$count" > "$count_file"

      if [ "$count" -eq 2 ] || [ $(( count % 4 )) -eq 0 ]; then
        jq -n --arg n "$count" '{
          hookSpecificOutput: {
            additionalContext: ("This is failed command number " + $n + " in a row. Before trying another variation, search the web (searxng_web_search) for the exact error message with the tool and version involved, read the most relevant page (web_url_read), then say what you found and fix it.")
          }
        }'
      fi
    '';
  };
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
                  hooks = {
                    PostToolUse = [
                      {
                        matcher = "run_shell_command";
                        hooks = [
                          {
                            type = "command";
                            command = lib.getExe searchNudge;
                            name = "search-nudge";
                            timeout = 5;
                          }
                        ];
                      }
                    ];
                  };
                });
              };

              # Global context. qwen's /memory writes here
              # too, like settings.json, until the next switch.
              ".qwen/QWEN.md" = {
                force = true;
                source = ./QWEN.md;
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
