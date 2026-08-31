{
  config,
  lib,
  username,
  ...
}:

let
  cfg = config.modules.home.bat;
in
{
  options.modules.home.bat.enable =
    lib.mkEnableOption "bat pager and syntax-highlighting configuration";

  config = lib.mkIf cfg.enable {
    home-manager = {
      users = {
        ${username} = {
          home = {
            sessionVariables = {
              MANPAGER = "sh -c 'col -bx | bat -l man -p'";
            };
          };

          programs = {
            bat = {
              enable = true;

              config = {
                decorations = "auto";
                diff-context = "3";
                italic-text = "always";
                pager = "less -FR";
                paging = "auto";
                style = "numbers,changes,header";
                tabs = "2";
                wrap = "never";
              };
            };
          };
        };
      };
    };
  };
}
