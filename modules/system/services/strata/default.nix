{ config, lib, pkgs, ... }:

let
  cfg = config.modules.system.services.strata;

  package = pkgs.callPackage ../../../../pkgs/strata { };
  terminal = "${package}/${package.passthru.terminal}";

  unitName = name: "strata-${name}";

  otherUnits = name: map (n: "${unitName n}.service") (lib.attrNames (removeAttrs cfg.models [ name ]));

  # What `strata launch` writes for serve/server.py, with the engine and the
  # terminal from the store instead of its installed copies.
  runConfig =
    name: model:
    pkgs.writeText "strata-${name}.json" (
      builtins.toJSON {
        exe = "${package}/${package.passthru.engine}";
        args = [
          "--pack"
          model.pack
          "--native"
          model.gguf
          "--ple-gguf"
          model.gguf
          "--expert-profile"
          "${terminal}/data/expert-profile.bin"
          "--expert-cache"
          "auto"
          "--prefill"
          "auto"
          "--max-context"
          (toString cfg.settings.context)
          "--kv"
          cfg.settings.kv
          "--kv-resident"
          (toString cfg.settings.kvResident)
        ]
        ++ lib.optionals (model.mtp != null) [
          "--spec"
          "4"
          "--spec-min-p"
          "0.5"
          "--mtp"
          model.mtp
        ];
        cwd = terminal;
        tokenizer = "${model.pack}/tokenizer";
        model_name = model.servedName;
        log = "/var/log/strata/${name}.engine.log";
        lib_dirs = [ ];
        inherit (cfg.settings) host port;
        gpu = 0;
        gpus_asked = true;
        # How long the engine may take to load before the server gives up;
        # `strata launch` sized it for this model's 76 GB.
        engine_ready_s = 946;
      }
    );
in
{
  options = {
    modules = {
      system = {
        services = {
          strata = {
            enable = lib.mkEnableOption "a local LLM server on Strata";

            # Strings, not paths: a path literal would copy the model into
            # the store. The pack and the draft layer are what `strata
            # launch` prepares once from the GGUF (`strata` is installed).
            models = lib.mkOption {
              type = lib.types.attrsOf (
                lib.types.submodule {
                  options = {
                    gguf = lib.mkOption {
                      type = lib.types.str;
                      description = "First shard of the model's GGUF.";
                    };
                    pack = lib.mkOption {
                      type = lib.types.str;
                      description = "Strata's pack of the model.";
                    };
                    mtp = lib.mkOption {
                      type = lib.types.nullOr lib.types.str;
                      default = null;
                      description = "Runtime folder of the MTP draft layer, or null to decode without drafting.";
                    };
                    servedName = lib.mkOption {
                      type = lib.types.str;
                      description = "Model ID the server answers to.";
                    };
                  };
                }
              );
              description = ''
                Models by name. Each gets its own strata-<name> unit; they
                share a port and starting one stops the others.
              '';
            };

            default = lib.mkOption {
              type = lib.types.str;
              description = "Model the coding agents pick at startup.";
            };

            # Measured on alpha (8 GB RTX 4070 Laptop, Swift 1.5 IQ3_XXS,
            # 2026-11-08): 128K with an 8/4-bit KV keeps 47 GB of RAM and
            # 7.3 GB of VRAM in use; 54 t/s generation on average (28-78)
            # through qwen-code, prompts at ~800 t/s, 70% of drafts accepted.
            # The resident KV and the draft settings are what `strata launch`
            # picked for this card.
            settings = lib.mkOption {
              type = lib.types.attrs;
              readOnly = true;
              default = {
                host = "127.0.0.1";
                port = 8080;
                context = 131072;
                kv = "k8v4";
                kvResident = 32768;
              };
              description = "Server settings shared by every model.";
            };
          };
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.models ? ${cfg.default};
        message = "modules.system.services.strata.default must name one of its models.";
      }
    ];

    # Packs and draft layers are prepared by hand with it.
    environment = {
      systemPackages = [ package ];
    };

    # The RTX's device nodes are world-writable; no extra groups.
    users = {
      users = {
        strata = {
          isSystemUser = true;
          group = "strata";
        };
      };
      groups = {
        strata = { };
      };
    };

    systemd = {
      services = lib.mapAttrs' (
        name: model:
        lib.nameValuePair (unitName name) {
          description = "Strata LLM server (${name})";
          after = [ "network.target" ];
          # Started by hand: while a model is loaded the RTX never suspends.
          conflicts = otherUnits name;
          unitConfig = {
            RequiresMountsFor = [
              model.gguf
              model.pack
            ];
          };

          environment = {
            HOME = "/var/lib/strata";
            XDG_STATE_HOME = "/var/lib/strata/state";
            XDG_DATA_HOME = "/var/lib/strata/data";
            XDG_CACHE_HOME = "/var/cache/strata";
            STRATA_UPDATE_CHECK = "0";
            PYTHONDONTWRITEBYTECODE = "1";
            # NVML for the server's checks of the card.
            LD_LIBRARY_PATH = "/run/opengl-driver/lib";
          };

          serviceConfig = {
            ExecStart = toString [
              "${terminal}/python/bin/python3.12"
              "-m"
              "serve.server"
              "--engine"
              "strata"
              "--config"
              (runConfig name model)
              "--host"
              cfg.settings.host
              "--port"
              (toString cfg.settings.port)
            ];
            WorkingDirectory = terminal;
            Restart = "on-failure";
            RestartSec = 30;
            # A stuck engine leaves the server waiting on open connections.
            TimeoutStopSec = 30;

            User = "strata";
            Group = "strata";
            StateDirectory = "strata";
            CacheDirectory = "strata";
            LogsDirectory = "strata";
            AmbientCapabilities = [ "" ];
            CapabilityBoundingSet = [ "" ];
            LockPersonality = true;
            NoNewPrivileges = true;
            PrivateDevices = false; # The RTX.
            PrivateMounts = true;
            PrivateTmp = true;
            ProtectClock = true;
            ProtectControlGroups = true;
            ProtectHome = true;
            ProtectHostname = true;
            ProtectKernelLogs = true;
            ProtectKernelModules = true;
            ProtectKernelTunables = true;
            ProtectSystem = "strict";
            RemoveIPC = true;
            RestrictAddressFamilies = [
              "AF_INET"
              "AF_INET6"
              "AF_UNIX"
            ];
            RestrictNamespaces = true;
            RestrictRealtime = true;
            RestrictSUIDSGID = true;
            SystemCallArchitectures = "native";
          };
        }
      ) cfg.models;
    };
  };
}
