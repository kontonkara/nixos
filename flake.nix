{
  inputs = {
    nixpkgs = {
      url = "github:nixos/nixpkgs/nixos-unstable";
    };
    chaotic = {
      url = "github:chaotic-cx/nyx/nyxpkgs-unstable";
      # No nixpkgs follows: nyx-overlay builds its packages on nyx's own
      # nixpkgs pin, and nyx-cache only holds kernels built from that pin.
      inputs.home-manager.follows = "home-manager";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixpak = {
      url = "github:nixpak/nixpak";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    niri = {
      url = "github:sodiboo/niri-flake";
      inputs.nixpkgs.follows = "nixpkgs";
      # pkgs.niri-unstable is what the niri module uses; niri-flake's own
      # pin of it lags behind upstream, so track niri main directly.
      inputs.niri-unstable.url = "github:niri-wm/niri";
    };
    llm-agents = {
      url = "github:numtide/llm-agents.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    stylix = {
      # master tracks nixos-unstable (release-XX.YY branches follow stable).
      url = "github:nix-community/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { self, nixpkgs, chaotic, sops-nix, home-manager, niri, ... }@inputs:
    let
      inherit (nixpkgs) lib;

      username = "kontonkara";
      system = "x86_64-linux";

      discoverModules =
        {
          root,
          matches,
          excludedDirectories ? [ ],
        }:
        let
          walk =
            directory:
            let
              entries = builtins.readDir directory;
            in
            lib.concatMap (
              name:
              let
                entryType = entries.${name};
                path = directory + "/${name}";
              in
              if entryType == "directory" then
                if builtins.elem name excludedDirectories then [ ] else walk path
              else if entryType == "regular" && matches name then
                [ path ]
              else
                [ ]
            ) (builtins.attrNames entries);
        in
        walk root;

      sharedModules =
        (discoverModules {
          root = ./modules;
          matches = name: name == "default.nix";
        })
        ++ (discoverModules {
          root = ./users;
          matches = name: name == "default.nix";
        });

      hostModules =
        host:
        discoverModules {
          root = ./hosts/${host};
          matches = name: lib.hasSuffix ".nix" name;
        };

      mkHost =
        host:
        lib.nixosSystem {
          inherit system;
          specialArgs = {
            inherit
              host
              inputs
              self
              username
              ;
          };
          modules =
            sharedModules
            ++ hostModules host
            ++ [
              chaotic.nixosModules.nyx-overlay
              niri.nixosModules.niri
              sops-nix.nixosModules.sops
              home-manager.nixosModules.home-manager
            ];
        };
    in
    {
      nixosConfigurations = {
        alpha = mkHost "alpha";
      };
    };
}
