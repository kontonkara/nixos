{
  inputs = {
    nixpkgs = {
      url = "github:nixos/nixpkgs/nixos-unstable";
    };
    chaotic = {
      url = "github:chaotic-cx/nyx/nyxpkgs-unstable";
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
    llm-agents = {
      url = "github:numtide/llm-agents.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      chaotic,
      sops-nix,
      home-manager,
      nixpak,
      ...
    }@inputs:
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

      sharedModules = discoverModules {
        root = ./.;
        matches = name: name == "default.nix";
        excludedDirectories = [
          ".direnv"
          ".git"
          "hosts"
          "lib"
        ];
      };

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
