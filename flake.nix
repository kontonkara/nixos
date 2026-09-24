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
    spicetify-nix = {
      url = "github:Gerg-L/spicetify-nix";
      # Its nixpkgs only builds the extension sources and crudini/zenity for
      # the patch step; Spotify and spicetify-cli come from our pkgs.
      inputs.nixpkgs.follows = "nixpkgs";
      # Same nix-systems/default pin; its own node would renumber stylix's.
      inputs.systems.follows = "llm-agents/systems";
    };
  };

  outputs =
    { nixpkgs, chaotic, sops-nix, home-manager, niri, ... }@inputs:
    let
      inherit (nixpkgs) lib;

      username = "kontonkara";

      # Every default.nix under modules/ and users/ is imported as a module
      # gated by its own enable option, so packages live in pkgs/, not here.
      # Other files next to it (layouts, patches) are imported by hand.
      sharedModules = lib.fileset.toList (
        lib.fileset.unions (
          map (lib.fileset.fileFilter (file: file.name == "default.nix")) [
            ./modules
            ./users
          ]
        )
      );

      hostModules =
        host: lib.fileset.toList (lib.fileset.fileFilter (file: file.hasExt "nix") ./hosts/${host});

      # The system comes from nixpkgs.hostPlatform in the host's hardware.nix.
      mkHost =
        host:
        lib.nixosSystem {
          specialArgs = {
            inherit
              host
              inputs
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
