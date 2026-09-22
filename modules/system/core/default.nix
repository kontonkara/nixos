{ config, lib, ... }:

let
  cfg = config.modules.system.core;
in
{
  options = {
    modules = {
      system = {
        core = {
          enable = lib.mkEnableOption "core system settings";
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    system = {
      stateVersion = "26.05";
    };

    nix = {
      settings = {
        experimental-features = [
          "nix-command"
          "flakes"
        ];
      };
    };

    nixpkgs = {
      config = {
        allowUnfree = true;
      };
    };
  };
}
