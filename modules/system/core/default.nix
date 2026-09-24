{ config, pkgs, lib, ... }:

let
  cfg = config.modules.system.core;
in
{
  options = {
    modules = {
      system = {
        core = {
          enable = lib.mkEnableOption "core NixOS configuration";
        };
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

    nix = {
      # Flake-only: drops the installer's stale nixos-26.05 channel from
      # NIX_PATH; <nixpkgs> keeps resolving to the flake's nixpkgs.
      channel = {
        enable = false;
      };

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
        # The legacy CLI's ~/.nix-profile and ~/.nix-defexpr go under
        # $XDG_STATE_HOME/nix. Nothing installs into either: Home Manager uses
        # /etc/profiles/per-user (useUserPackages) and channels are off.
        use-xdg-base-directories = true;
      };

      # Local mesa/niri/kernel-module builds shouldn't stutter the desktop.
      # The IO class is left alone: NVMe here uses the `none` scheduler,
      # which ignores ioprio.
      daemonCPUSchedPolicy = "idle";
    };

    hardware = {
      firmware = [ pkgs.linux-firmware ];
    };
  };
}
