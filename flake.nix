{
  inputs = {
    nixpkgs = {
      url = "github:nixos/nixpkgs/nixos-unstable";
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
  };

  outputs = { self, nixpkgs, sops-nix, home-manager, nixpak, ... }@inputs:
    let
      username = "kontonkara";
      system = "x86_64-linux";
    in {
      nixosConfigurations = {
        alpha = nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = {
            host = "alpha";
            inherit self inputs username;
          };
          modules = [
            ./hosts/alpha
            sops-nix.nixosModules.sops
            home-manager.nixosModules.home-manager
          ];
        };
      };
    };
}
