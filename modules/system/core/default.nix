{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config.modules.core;
in
{
  options = {
    modules = {
      core = {
        enable = lib.mkEnableOption "core NixOS configuration";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    system = {
      stateVersion = "26.05";
    };

    nixpkgs = {
      config = {
        allowUnfree = true;
      };
    };

    chaotic = {
      nyx = {
        overlay = {
          flakeNixpkgs = {
            config = {
              allowUnfree = true;
            };
          };
        };
      };
    };

    nix = {
      settings = {
        experimental-features = [
          "nix-command"
          "flakes"
        ];
        substituters = lib.mkForce [
          "https://nyx-cache.chaotic.cx"
          "https://nixos-cache-proxy.elxreno.com"
          "https://nix-community.cachix.org"
          "https://cache.nixos.org"
        ];
        trusted-public-keys = [
          "nyx-cache.chaotic.cx:dJxTrgMC3V3cFfyIiBQDQorG6k1LsqurH/srpMSq7qk="
          "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
          "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        ];
        auto-optimise-store = true;
        max-jobs = 1;
        cores = 24;
        trusted-users = [
          "root"
          "@wheel"
        ];
      };
    };

    hardware = {
      firmware = [ pkgs.linux-firmware ];
    };
  };
}
