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
      "sing-box/vless/address" = { };
      "sing-box/vless/host" = { };
      "sing-box/vless/path" = { };
      "sing-box/vless/sni" = { };
      "sing-box/vless/uuid" = { };
    };
  };
}