{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.modules.ccache;

  cacheConfig = pkgs.writeText "ccache.conf" ''
    max_size = ${cfg.maxSize}
    compression = true
    compression_level = 1
    compiler_check = content
    umask = 007
  '';

  wrapperConfig = ''
    export CCACHE_DIR=${lib.escapeShellArg (toString cfg.cacheDir)}

    if [ ! -d "$CCACHE_DIR" ] || [ ! -w "$CCACHE_DIR" ]; then
      export CCACHE_DISABLE=1
    fi
  '';
in
{
  options = {
    modules = {
      ccache = {
        enable = lib.mkEnableOption "a persistent compiler cache for selected packages";

        cacheDir = lib.mkOption {
          type = lib.types.path;
          default = "/var/cache/ccache";
          description = "Persistent ccache directory exposed to Nix build sandboxes.";
        };

        maxSize = lib.mkOption {
          type = lib.types.strMatching "[0-9]+([.][0-9]+)?[KMGTP]?";
          default = "50G";
          description = "Maximum size of the persistent compiler cache.";
        };

        wrapStdenv = lib.mkOption {
          type = lib.types.raw;
          internal = true;
          readOnly = true;
          description = "Function wrapping a selected stdenv compiler with the configured ccache instance.";
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    modules.ccache.wrapStdenv =
      stdenv:
      pkgs.ccacheStdenv.override {
        inherit stdenv;
        extraConfig = wrapperConfig;
      };

    programs.ccache = {
      enable = true;
      inherit (cfg) cacheDir;
      owner = "root";
      group = "nixbld";
    };

    systemd.tmpfiles.rules = [
      "L+ ${toString cfg.cacheDir}/ccache.conf - - - - ${cacheConfig}"
    ];

    nix.settings.extra-sandbox-paths = [ "${toString cfg.cacheDir}?" ];
  };
}
