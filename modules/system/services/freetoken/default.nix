{ config, lib, pkgs, inputs, ... }:

let
  cfg = config.modules.system.services.freetoken;

  package = pkgs.callPackage ../../../../pkgs/freetoken { inherit inputs; };

  # FreeToken compiles part of its kernels (flashinfer, its own tvm-ffi ones,
  # Triton's launcher) on first use and keeps them in the cache directory.
  cuda = pkgs.cudaPackages_13.cudatoolkit;
  driverLib = "/run/opengl-driver/lib";

  unitName = name: "freetoken-${name}";

  otherUnits = name: map (n: "${unitName n}.service") (lib.attrNames (removeAttrs cfg.models [ name ]));
in
{
  options = {
    modules = {
      system = {
        services = {
          freetoken = {
            enable = lib.mkEnableOption "a local LLM server on FreeToken";

            # Strings, not paths: a path literal would copy the model into
            # the store.
            models = lib.mkOption {
              type = lib.types.attrsOf lib.types.str;
              example = {
                ornith = "/data/models/Ornith-1.5-35B-A3B-NVFP4";
              };
              description = ''
                Checkpoint directories by name. Each gets its own
                freetoken-<name> unit; they share a port and starting one
                stops the others.
              '';
            };

            default = lib.mkOption {
              type = lib.types.str;
              description = "Model the coding agents pick at startup.";
            };

            # Measured on alpha (8 GB RTX 4070 Laptop, Ornith-1.5-35B-A3B
            # NVFP4): hybrid runs the experts missing from the GPU cache
            # partly on the CPU and partly over PCIe, which doubles generation
            # over offload's PCIe-only misses. Left to itself, FreeToken fills
            # all VRAM with experts and KV and runs out on the second request;
            # an explicit expert count and an fp8 128k KV leave room for the
            # prefill buffers. The embedding table in RAM frees ~1 GB for 400
            # more experts. The model's MTP head drafts a token per step
            # (1.6-1.8 accepted). With the environment below: 83 t/s
            # generation short, 80 at 16k, 74 at 56k; prompts at 4250 t/s
            # (16k) and 3200 (56k). ik_llama.cpp did 52/46/32 and ~1000.
            settings = lib.mkOption {
              type = lib.types.attrs;
              readOnly = true;
              default = {
                host = "127.0.0.1";
                port = 8080;
                num-tokens = 131072;
                kv-cache-dtype = "fp8_e4m3";
                moe-strategy = "hybrid";
                moe-cache-size = 1500;
                embed-weights = "host";
                # From the fork author's hybrid setup: a quarter of each
                # step's misses over PCIe, the rest on 8 CPU threads (all 16
                # cores were slower), and cached experts copied on the GPU
                # during prefill.
                moe-hybrid-fetch-fraction = 0.25;
                moe-cpu-threads = 8;
                moe-prefill-hit-d2d = true;
                mtp-verify = true;
                max-running-requests = 1;
                text-model-only = true;
              };
              description = "ft serve flags shared by every model.";
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
        message = "modules.system.services.freetoken.default must name one of its models.";
      }
    ];

    # The RTX's device nodes are world-writable; no extra groups.
    users = {
      users = {
        freetoken = {
          isSystemUser = true;
          group = "freetoken";
        };
      };
      groups = {
        freetoken = { };
      };
    };

    systemd = {
      services = lib.mapAttrs' (
        name: model:
        lib.nameValuePair (unitName name) {
          description = "FreeToken LLM server (${name})";
          after = [ "network.target" ];
          # Started by hand: while a model is loaded the RTX never suspends.
          conflicts = otherUnits name;
          unitConfig = {
            RequiresMountsFor = [ model ];
          };

          path = [
            cuda
            pkgs.stdenv.cc
            pkgs.ninja
            # nixpkgs' ninja spawns its commands through `sh` on PATH, which a
            # unit's default path lacks.
            pkgs.bash
          ];

          environment = {
            HOME = "/var/cache/freetoken";
            XDG_CACHE_HOME = "/var/cache/freetoken";
            TRITON_CACHE_DIR = "/var/cache/freetoken/triton";
            CUDA_HOME = "${cuda}";
            # nvcc.profile in the merged toolkit points at nvcc's own output,
            # so the runtime headers and libraries need spelling out.
            CPATH = "${cuda}/include";
            LIBRARY_PATH = "${cuda}/lib:${cuda}/lib/stubs";
            # The wheels dlopen libcuda; Triton would ask /sbin/ldconfig.
            LD_LIBRARY_PATH = driverLib;
            TRITON_LIBCUDA_PATH = driverLib;

            # Idle KV pages and GDN state slots hold experts until the context
            # needs them.
            FREETOKEN_KV_LEND = "1";
            FREETOKEN_KV_LEND_GDN = "1";
            # The fork author's hybrid decode path: CPU-side expert prefetch,
            # misses copied by the copy engine under the hit GEMM, and drafts
            # below 0.45 confidence not verified.
            FREETOKEN_CPU_MOE_PREFETCH = "load";
            FREETOKEN_DEMAND_COPY = "ce";
            FREETOKEN_HYBRID_SPLIT_GEMM = "copy";
            FREETOKEN_SPEC_GATE = "0.45";
          };

          serviceConfig = {
            ExecStart = toString [
              (lib.getExe' package "ft")
              "serve"
              (lib.cli.toCommandLine (optionName: {
                option = "--${optionName}";
                sep = " ";
                explicitBool = false;
                formatArg = lib.generators.mkValueStringDefault { };
              }) (cfg.settings // { inherit model; served-model-name = name; }))
            ];
            Restart = "on-failure";
            RestartSec = 30;
            # A dead backend leaves the frontend waiting on open connections.
            TimeoutStopSec = 20;

            # A fixed user, not DynamicUser: systemd mounts a dynamic user's
            # /var/cache/private/<name> noexec, and the JIT kernels are loaded
            # from the cache directory.
            User = "freetoken";
            Group = "freetoken";
            CacheDirectory = "freetoken";
            WorkingDirectory = "/var/cache/freetoken";
            # Lighter than nixpkgs' llama-cpp set: the JIT needs writable
            # executable memory, and the RAM checks read /proc/meminfo.
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
              # torch.distributed's gloo lists interfaces through getifaddrs.
              "AF_NETLINK"
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
