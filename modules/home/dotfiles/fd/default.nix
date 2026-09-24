{ config, lib, username, ... }:

let
  cfg = config.modules.home.fd;
in
{
  options = {
    modules = {
      home = {
        fd = {
          enable = lib.mkEnableOption "fd file search";
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    home-manager = {
      users = {
        ${username} = {
          programs = {
            fd = {
              enable = true;
              # Only the interactive `fd` (a fish alias); fzf.fish and yazi
              # run the binary with its defaults.
              hidden = true;

              # ~/.config/fd/ignore also applies to fzf.fish and yazi, so only
              # VCS/direnv metadata that --hidden drags in; build dirs are
              # already gitignored inside repos.
              ignores = [
                ".direnv/"
                ".git/"
                ".jj/"
              ];
            };
          };
        };
      };
    };
  };
}
