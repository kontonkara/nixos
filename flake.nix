{
  inputs = {
    nixpkgs = {
      url = "github:nixos/nixpkgs/nixos-unstable";
    };
    llm-agents = {
      url = "github:numtide/llm-agents.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, ... }@inputs:
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
          ];
        };
      };
    };
}
