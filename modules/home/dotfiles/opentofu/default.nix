{ config, lib, pkgs, username, ... }:

let
  cfg = config.modules.home.opentofu;

  pluginCache = "${config.home-manager.users.${username}.xdg.cacheHome}/opentofu/plugin-cache";
in
{
  options = {
    modules = {
      home = {
        opentofu = {
          enable = lib.mkEnableOption "opentofu with a shared provider cache";
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    # OpenTofu only creates the cache dir when it first installs a provider;
    # until then every command reports the whole CLI config as broken.
    systemd = {
      user = {
        tmpfiles = {
          users = {
            ${username} = {
              rules = [
                "d ${pluginCache} - - - -"
              ];
            };
          };
        };
      };
    };

    home-manager = {
      users = {
        ${username} = {
          home = {
            packages = [
              pkgs.opentofu
            ];
          };

          # Only read while XDG_CONFIG_HOME is exported (Home Manager's xdg
          # module does) and neither ~/.tofurc nor ~/.terraformrc exists.
          xdg = {
            configFile = {
              "opentofu/tofurc" = {
                # Each root links providers from here instead of downloading
                # its own copy into .terraform/.
                text = ''
                  plugin_cache_dir = "${pluginCache}"
                '';
              };
            };
          };
        };
      };
    };
  };
}
