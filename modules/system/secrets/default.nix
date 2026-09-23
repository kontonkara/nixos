{ config, lib, ... }:

let
  cfg = config.modules.system.secrets;
in
{
  options = {
    modules = {
      system = {
        secrets = {
          enable = lib.mkEnableOption "sops-nix secrets";
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    sops = {
      defaultSopsFile = ./../../../secrets/secrets.yaml;
      age = {
        keyFile = "/var/lib/sops-nix/key.txt";
        sshKeyPaths = [ ];
      };
      secrets = {
        "kontonkara" = {
          neededForUsers = true;
        };
        "yandex-browser" = {
          owner = "kontonkara";
          mode = "0400";
        };
        # LUKS keyfile for /data; consumed by unlock-data.service.
        "data-luks-key" = {
          format = "binary";
          sopsFile = ./../../../secrets/data-luks-key;
          mode = "0400";
        };
      };
    };
  };
}
