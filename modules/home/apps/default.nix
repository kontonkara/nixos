{ config, lib, username, inputs, pkgs, ... }:

let
  cfg = config.modules.home.apps;
in
{
  options = {
    modules = {
      home = {
        apps = {
          enable = lib.mkEnableOption "home applications";
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    home-manager = {
      users = {
        ${username} = {
          home = {
            packages = with pkgs; [
              tree
              binutils
              duf
              dust
              file
              unzip
              wl-clipboard
              # AMD backend only: the NVIDIA one calls nvmlInit at start-up and
              # keeps the RTX out of D3cold while nvtop is open.
              nvtopPackages.amd
              inputs.llm-agents.packages.x86_64-linux.claude-code
            ];
          };
        };
      };
    };
  };
}
