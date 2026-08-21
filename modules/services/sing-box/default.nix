{ config, lib, ... }:

let
  cfg = config.modules.services.sing-box;

  proxyDomains = [
    "anthropic.com"
    "clau.de"
    "claude.ai"
    "claude.com"
    "claudemcpclient.com"
    "claudeusercontent.com"
    "sentry.io"
    "servd-anthropic-website.b-cdn.net"
    "statsig.com"
    "stripe.com"
    "usefathom.com"
    "deepl.com"
    "terraform.io"
    "grafana.com"
    "cdn.auth0.com"
    "identrust.com"
    "openai.com"
    "chatgpt.com"
    "chat.com"
    "crixet.com"
    "oaistatic.com"
    "oaistatsig.com"
    "oaiusercontent.com"
    "sora.com"
    "ai.com"
    "livekit.cloud"
    "chatgpt.livekit.cloud"
    "openai.com.cdn.cloudflare.net"
    "openaiapi-site.azureedge.net"
    "openaicom-api-bdcpf8c6d2e9atf6.z01.azurefd.net"
    "openaicom.imgix.net"
    "openaicomproductionae4b.blob.core.windows.net"
    "production-openaicom-storage.azureedge.net"
    "browser-intake-datadoghq.com"
    "default.exp-as.file.core.windows.net"
  ];

  fakeIpRange = "198.18.0.0/15";
  tunDnsAddress = "172.18.0.2";
  directDnsServer = "1.1.1.1";
in
{
  options = {
    modules = {
      services = {
        sing-box = {
          enable = lib.mkEnableOption "sing-box transparent proxy";
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    # DNS must enter sing-box so selected domains can receive FakeIP addresses.
    networking = {
      nameservers = [ tunDnsAddress ];
      networkmanager.dns = "none";
    };

    services.sing-box = {
      enable = true;

      settings = {
        log.level = "info";

        dns = {
          strategy = "ipv4_only";

          servers = [
            {
              type = "udp";
              tag = "dns-direct";
              server = directDnsServer;
            }
            {
              type = "fakeip";
              tag = "dns-fakeip";
              inet4_range = fakeIpRange;
            }
          ];

          rules = [
            {
              domain_suffix = proxyDomains;
              query_type = [
                "A"
                "AAAA"
              ];
              server = "dns-fakeip";
            }
          ];

          final = "dns-direct";
        };

        inbounds = [
          {
            type = "tun";
            address = [ "172.18.0.1/30" ];
            mtu = 65535;

            auto_route = true;
            auto_redirect = true;
            strict_route = true;
            stack = "system";

            route_address = [
              fakeIpRange
            ];
          }
        ];

        outbounds = [
          {
            type = "vless";
            tag = "proxy-out";

            server._secret = config.sops.secrets."sing-box/vless/address".path;
            server_port = 443;
            uuid._secret = config.sops.secrets."sing-box/vless/uuid".path;

            tls = {
              enabled = true;
              server_name._secret = config.sops.secrets."sing-box/vless/sni".path;
              insecure = false;

              utls = {
                enabled = true;
                fingerprint = "chrome";
              };
            };

            transport = {
              type = "ws";
              path._secret = config.sops.secrets."sing-box/vless/path".path;
              headers.Host._secret = config.sops.secrets."sing-box/vless/host".path;
            };
          }
          {
            type = "direct";
            tag = "direct";
          }
        ];

        route = {
          rules = [
            {
              action = "sniff";
            }
            {
              protocol = "dns";
              action = "hijack-dns";
            }
            {
              domain_suffix = proxyDomains;
              outbound = "proxy-out";
            }
          ];

          final = "direct";
          auto_detect_interface = true;
          default_domain_resolver = "dns-direct";
        };

        experimental = {
          cache_file.enabled = true;
          clash_api.external_controller = "127.0.0.1:9090";
        };
      };
    };

    systemd.services.sing-box = {
      after = lib.mkForce [
        "network.target"
        "nss-lookup.target"
      ];
      requires = lib.mkForce [ ];
      unitConfig.Requires = lib.mkForce [ ];
    };
  };
}
