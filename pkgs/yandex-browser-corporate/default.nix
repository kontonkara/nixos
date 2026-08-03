{ pkgs, inputs, ... }:

{
  nixpkgs.overlays = [
    (final: prev: {
      yandex-browser-corporate-unwrapped = final.callPackage ./yandex-browser-corporate.nix { };
      yandex-browser-customisation = final.callPackage ./yandex-browser-customisation.nix { };
      yandex-browser-corporate = final.callPackage ./package.nix { inherit inputs; };
    })
  ];

  environment.systemPackages = with pkgs; [
    yandex-browser-corporate
  ];
}
