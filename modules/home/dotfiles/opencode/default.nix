{ config, lib, inputs, username, ... }:

let
  cfg = config.modules.home.opencode;
in
{
  options = {
    modules = {
      home = {
        opencode = {
          enable = lib.mkEnableOption "opencode coding agent";
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    home-manager = {
      users = {
        ${username} = {
          programs = {
            opencode = {
              enable = true;
              # Upstream's release binary, bumped with the other llm-agents
              # tools rather than rebuilt from source like nixpkgs' opencode.
              package = inputs.llm-agents.packages.x86_64-linux.opencode;
            };
          };
        };
      };
    };
  };
}
