{ ... }:
{
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
    };
  };
}