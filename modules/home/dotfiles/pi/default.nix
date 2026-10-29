{ config, lib, pkgs, inputs, username, ... }:

let
  cfg = config.modules.home.pi;

  llm = config.modules.system.services.freetoken;
  server = llm.settings;
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
          };
        };
      };
    };
  };
}
