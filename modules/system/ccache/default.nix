{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.modules.ccache;

  ccacheStdenv = pkgs.ccacheStdenv.override {
    extraConfig = ''
      export CCACHE_DIR=${lib.escapeShellArg (toString cfg.cacheDir)}
      export CCACHE_MAXSIZE=${lib.escapeShellArg cfg.maxSize}
      export CCACHE_COMPRESS=1
      export CCACHE_COMPRESSLEVEL=1
      export CCACHE_COMPILERCHECK=content
      export CCACHE_UMASK=007

      if [ ! -d "$CCACHE_DIR" ] || [ ! -w "$CCACHE_DIR" ]; then
        export CCACHE_DISABLE=1
      fi
    '';
  };
in
{
  options.modules.ccache = {
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

    stdenv = lib.mkOption {
      type = lib.types.package;
      internal = true;
      readOnly = true;
      description = "Stdenv wrapping the compiler with the configured ccache instance.";
    };
  };

  config = lib.mkIf cfg.enable {
    modules.ccache.stdenv = ccacheStdenv;

    programs.ccache = {
      enable = true;
      inherit (cfg) cacheDir;
      owner = "root";
      group = "nixbld";
    };

    nix.settings.extra-sandbox-paths = [ "${toString cfg.cacheDir}?" ];
  };
}
