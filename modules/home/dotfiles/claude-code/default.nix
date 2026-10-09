{ config, lib, pkgs, inputs, username, ... }:

let
  cfg = config.modules.home.claude-code;

  hmConfig = config.home-manager.users.${username};

  # Mirrors the starship prompt (directory, git branch + dirty mark), then
  # model and context usage. Fish-style directory: parents shortened to one
  # letter, last three components kept in full.
  statusline = pkgs.writeShellScript "claude-statusline" ''
    export PATH=${lib.makeBinPath [ pkgs.coreutils pkgs.gawk pkgs.git pkgs.gnused pkgs.jq ]}
    input=$(cat)
    cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd')
    model=$(echo "$input" | jq -r '.model.display_name // empty')
    used=$(echo "$input" | jq -r '.context_window.used_percentage // empty')

    dir=$(printf '%s' "$cwd" | sed "s|^$HOME|~|" | awk -F/ '{
      n = NF; out = ""
      for (i = 1; i <= n; i++) {
        p = $i
        if (i <= n - 3 && i > 1 && length(p) > 1) p = substr(p, 1, 1)
        out = (i == 1) ? p : out "/" p
      }
      print out
    }')
    [ -z "$dir" ] && dir=/

    printf '\033[36m%s\033[0m' "$dir"

    branch=$(git -C "$cwd" --no-optional-locks symbolic-ref --short HEAD 2>/dev/null \
      || git -C "$cwd" --no-optional-locks rev-parse --short HEAD 2>/dev/null)
    if [ -n "$branch" ]; then
      mark=""
      [ -n "$(git -C "$cwd" --no-optional-locks status --porcelain 2>/dev/null | head -n 1)" ] && mark=" *"
      printf ' on \033[35mgit %s%s\033[0m' "$branch" "$mark"
    fi

    [ -n "$IN_NIX_SHELL" ] && printf ' via \033[34mnix %s\033[0m' "$IN_NIX_SHELL"
    [ -n "$model" ] && printf ' \033[2m|\033[0m \033[33m%s\033[0m' "$model"
    [ -n "$used" ] && printf ' \033[2m|\033[0m ctx %.0f%%' "$used"
    printf '\n'
  '';
in
{
  options = {
    modules = {
      home = {
        claude-code = {
          enable = lib.mkEnableOption "Claude Code coding agent";
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    home-manager = {
      users = {
        ${username} = {
          programs = {
            claude-code = {
              enable = true;
              # Upstream's release binary, bumped with the other llm-agents
              # tools; its wrapper already turns the auto-updater off.
              package = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.claude-code;

              # settings.json becomes a read-only store link: /model, /effort
              # and /config still change the running session, but saving
              # them as defaults fails, so defaults change here. The login
              # (.credentials.json) and ~/.claude.json stay the app's.
              settings = {
                model = "opus[1m]";
                modelSettings = {
                  claude-opus-5-5 = {
                    effortLevel = "xhigh";
                  };
                };
                theme = "auto";
                statusLine = {
                  type = "command";
                  command = "${statusline}";
                };
                autoCompactEnabled = true;
                remoteControlAtStartup = false;
                # Commits here carry no trailers: empty strings drop the
                # Co-Authored-By line and the PR footer (includeCoAuthoredBy
                # is deprecated in favour of this).
                attribution = {
                  commit = "";
                  pr = "";
                };
              };
            };
          };

          # Everything the app saved in the old file is declared above, so
          # take it over without leaving a settings.json.backup behind.
          home = {
            file = {
              "${hmConfig.programs.claude-code.configDir}/settings.json" = {
                force = true;
              };
            };
          };
        };
      };
    };
  };
}
