{
  config,
  lib,
  username,
  ...
}:

let
  cfg = config.modules.home.fd;
in
{
  options.modules.home.fd.enable = lib.mkEnableOption "fd file-search configuration";

  config = lib.mkIf cfg.enable {
    home-manager = {
      users = {
        ${username} = {
          programs = {
            fd = {
              enable = true;
              hidden = true;

              extraOptions = [
                "--follow"
              ];

              ignores = [
                ".cache/"
                ".direnv/"
                ".git/"
                ".jj/"
                ".next/"
                ".nuxt/"
                ".pytest_cache/"
                ".venv/"
                "__pycache__/"
                "build/"
                "coverage/"
                "dist/"
                "node_modules/"
                "result"
                "result-*"
                "target/"
              ];
            };
          };
        };
      };
    };
  };
}
