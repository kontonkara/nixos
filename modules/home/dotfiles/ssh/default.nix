{ config, lib, username, ... }:

let
  cfg = config.modules.home.ssh;
in
{
  options = {
    modules = {
      home = {
        ssh = {
          enable = lib.mkEnableOption "openssh client config";
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    home-manager = {
      users = {
        ${username} = {
          programs = {
            ssh = {
              enable = true;
              # Home Manager's implicit defaults are deprecated and warn; the
              # "*" block below is the whole default config.
              enableDefaultConfig = false;

              settings = {
                "github.com" = {
                  HostName = "github.com";
                  User = "git";
                  IdentityFile = "~/.ssh/github";
                  IdentitiesOnly = true;
                };

                # Rendered last, so the host blocks above win. No
                # AddKeysToAgent: gcr-ssh-agent already offers every ~/.ssh key
                # with a .pub beside it and runs ssh-add, with its
                # keyring-backed prompt, on first use.
                # No HashKnownHosts: fish completes ssh hosts from known_hosts
                # and skips hashed entries.
                "*" = {
                  # One connection per host for bursts of git fetch/push.
                  ControlMaster = "auto";
                  # $XDG_RUNTIME_DIR spelled with %i (uid): ssh aborts outright
                  # on an unset ${VAR}, e.g. under env -i or sudo -u.
                  ControlPath = "/run/user/%i/ssh-%C";
                  ControlPersist = "10m";
                  # A master left dead by suspend or a network switch exits
                  # after ~90s, not after TCP keepalive's two hours; until
                  # then new sessions to that host hang on it.
                  ServerAliveInterval = 30;
                  ServerAliveCountMax = 3;
                };
              };
            };
          };
        };
      };
    };
  };
}
