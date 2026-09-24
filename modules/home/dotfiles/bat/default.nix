{ config, lib, pkgs, username, ... }:

let
  cfg = config.modules.home.bat;
in
{
  options = {
    modules = {
      home = {
        bat = {
          enable = lib.mkEnableOption "bat pager and man page highlighting";
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    home-manager = {
      users = {
        ${username} = {
          home = {
            sessionVariables = {
              # bat's documented MANPAGER recipe as a script, so no quoting has
              # to survive fish: strip groff's SGR escapes and overstrikes
              # (`col -bx` only handles the latter), then highlight.
              MANPAGER = toString (
                pkgs.writeShellScript "bat-manpager" ''
                  ${lib.getExe pkgs.gawk} '{ gsub(/\x1B\[[0-9;]*m/, "", $0); gsub(/.\x08/, "", $0); print }' | ${lib.getExe pkgs.bat} -p -lman
                ''
              );
            };
          };

          programs = {
            bat = {
              enable = true;

              config = {
                decorations = "auto";
                diff-context = "3";
                italic-text = "always";
                # bat maps .envrc to DotENV, but direnv runs it as bash.
                map-syntax = [
                  ".envrc:Bourne Again Shell (bash)"
                ];
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
