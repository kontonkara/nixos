{ ... }:

{
  sops = {
    defaultSopsFile = ./../../../secrets/secrets.yaml;

    age = {
      keyFile = "/var/lib/sops-nix/keys.txt";
    };

    secrets = {
      "kontonkara" = {
        neededForUsers = true;
      };
    };
  };
}