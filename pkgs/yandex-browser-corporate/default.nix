{
  pkgs,
  nixpak,
  lib ? pkgs.lib,

  licenseSeedPath ? "/run/secrets/yandex-browser",
  passwordStore ? "gnome-libsecret",
  extraArgs ? [ ],
  appId ? "ru.yandex.Browser.Corporate",
  extraManagedPolicies ? { },
}:

let
  unwrapped = pkgs.callPackage ./unwrapped.nix { };
  customisation = pkgs.callPackage ./customisation.nix { };

  mkNixPak = nixpak.lib.nixpak {
    inherit pkgs;
    inherit (pkgs) lib;
  };

  sandboxed = import ./sandbox.nix {
    inherit
      mkNixPak
      lib
      pkgs
      unwrapped
      customisation
      licenseSeedPath
      passwordStore
      extraArgs
      appId
      extraManagedPolicies
      ;
  };
in
sandboxed.config.env.overrideAttrs (old: {
  passthru = (old.passthru or { }) // {
    inherit
      unwrapped
      customisation
      licenseSeedPath
      appId
      ;
  };
})
