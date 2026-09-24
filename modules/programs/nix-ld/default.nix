{ config, lib, ... }:

let
  cfg = config.modules.programs.nix-ld;
in
{
  options = {
    modules = {
      programs = {
        nix-ld = {
          enable = lib.mkEnableOption "nix-ld loader for prebuilt foreign binaries";
        };
      };
    };
  };

  # Prebuilt binaries (language servers editors download, pip/npm native
  # wheels, vendor CLIs) hardcode /lib64/ld-linux-x86-64.so.2. nix-ld puts a
  # shim there that only reads NIX_LD_LIBRARY_PATH, so Nix-built programs are
  # unaffected. The default library set (libstdc++, zlib, openssl, curl, …)
  # covers CLI tools; GUI binaries would need programs.nix-ld.libraries.
  config = lib.mkIf cfg.enable {
    programs = {
      nix-ld = {
        enable = true;
      };
    };
  };
}
