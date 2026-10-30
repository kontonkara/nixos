{ config, lib, pkgs, ... }:

let
  cfg = config.modules.system.services.searxng;

  freetoken = config.modules.system.services.freetoken;
  freetokenUnits = map (name: "freetoken-${name}.service") (lib.attrNames freetoken.models);

  host = "127.0.0.1";
  port = 8888;

  secretDir = "/var/lib/searx-secret";
in
{
  options = {
    modules = {
      system = {
        services = {
          searxng = {
            enable = lib.mkEnableOption "a local SearXNG for the coding agents' web search";

            url = lib.mkOption {
              type = lib.types.str;
              readOnly = true;
              default = "http://${host}:${toString port}";
              description = "Where the agents reach SearXNG.";
            };
          };
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    services = {
      searx = {
        enable = true;
        environmentFile = "${secretDir}/env";
        settings = {
          server = {
            bind_address = host;
            inherit port;
            secret_key = "$SEARX_SECRET_KEY";
            # Only the agents on this machine ask it.
            limiter = false;
            image_proxy = false;
          };
          search = {
            # json is what the agents read.
            formats = [
              "html"
              "json"
            ];
            safe_search = 0;
          };
        };
      };
    };

    systemd = {
      services = {
        # SearXNG refuses its default key; ~/nixos is public, so the key is
        # made once on the machine instead of living in the repo.
        searx-secret = {
          description = "Generate the SearXNG secret key";
          unitConfig = {
            ConditionPathExists = "!${secretDir}/env";
          };
          serviceConfig = {
            Type = "oneshot";
            StateDirectory = "searx-secret";
            StateDirectoryMode = "0700";
            UMask = "0077";
          };
          script = ''
            printf 'SEARX_SECRET_KEY=%s\n' "$(${lib.getExe' pkgs.openssl "openssl"} rand -hex 32)" > ${secretDir}/env
          '';
        };

        searx-init = {
          requires = [ "searx-secret.service" ];
          after = [ "searx-secret.service" ];
        };

        # Runs only beside the model server: started and stopped with any
        # freetoken-<name> unit instead of at boot.
        searx = {
          wantedBy = lib.mkForce freetokenUnits;
          partOf = freetokenUnits;
        };
      };
    };
  };
}
