{ config, lib, pkgs, inputs, ... }:

let
  cfg = config.modules.system.nix-optimized;
in
{
  options = {
    modules = {
      system = {
        nix-optimized = {
          enable = lib.mkEnableOption "Nix built with PGO and evaluation speedups (nix-optimized)";
        };
      };
    };
  };

  # The latest Nix release, profile-guided and with the flake's evaluation
  # patches: alpha's system evaluates in 4.8 s instead of stock 2.34's 6.4 s
  # (hyperfine, 2026-10-05). The patches are the author's and not upstream
  # yet; the build runs Nix's full test suite.
  config = lib.mkIf cfg.enable {
    nix = {
      package = inputs.nix-optimized.packages.${pkgs.stdenv.hostPlatform.system}.nix-optimized;

      # Its CI pushes every build here; without it each bump of the input
      # rebuilds and retrains Nix locally (~20 min). The key is the author's,
      # so it vouches for whatever it signs, not only for Nix.
      settings = {
        extra-substituters = [
          "https://elxreno.cachix.org"
        ];
        extra-trusted-public-keys = [
          "elxreno.cachix.org-1:ozSPSY5S3/TpbcXi+/DdtSj1JlK3CPz3G+F92yRBXDQ="
        ];
      };
    };
  };
}
