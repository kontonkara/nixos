{ config, lib, ... }:

let
  cfg = config.modules.system.services.sing-box;

  proxyDomains = [
    # anthropic / claude — geosite:anthropic
    "anthropic.com"
    "clau.de"
    "claude.ai"
    "claude.com"
    "claudemcpclient.com"
    "claudemcpcontent.com"
    "claudeusercontent.com"
    "servd-anthropic-website.b-cdn.net"
    # claude support / telemetry
    "statsig.com"
    "stripe.com"
    "usefathom.com"
    "sentry.io"
    # openai — geosite:openai
    "openai.com"
    "chatgpt.com"
    "chatgpt.site"
    "chat.com"
    "crixet.com"
    "oaistatic.com"
    "oaistatsig.com"
    "oaiusercontent.com"
    "sora.com"
    "ai.com"
    "livekit.cloud"
    "openai.com.cdn.cloudflare.net"
    "openaiapi-site.azureedge.net"
    "openaiassets.blob.core.windows.net"
    "openaicom-api-bdcpf8c6d2e9atf6.z01.azurefd.net"
    "openaicom.imgix.net"
    "openaicomproductionae4b.blob.core.windows.net"
    "production-openaicom-storage.azureedge.net"
    "openai.qualtrics.com"
    # misc from previous set
    "deepl.com"
    "terraform.io"
    "grafana.com"
    "cdn.auth0.com"
    "identrust.com"
    "browser-intake-datadoghq.com"
    "default.exp-as.file.core.windows.net"
  ];

  fakeIpRange = "198.18.0.0/15";
  tunDnsAddress = "172.18.0.2";
  # A distinctive name rather than tun0, so trusting it in the firewall
  # can't accidentally trust some future VPN that grabs tun0.
  tunInterface = "sing0";
  directDnsServer = "1.1.1.1";
in
{
  options = {
    modules = {
      system = {
        services = {
          sing-box = {
            enable = lib.mkEnableOption "sing-box transparent proxy";
          };
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    sops.secrets = lib.genAttrs
      [
        "sing-box/vless/address"
        "sing-box/vless/host"
        "sing-box/vless/path"
        "sing-box/vless/sni"
        "sing-box/vless/uuid"
      ]
      (_: {
        restartUnits = [ "sing-box.service" ];
      });

    # DNS must enter sing-box so selected domains can receive FakeIP addresses.
    networking = {
      nameservers = [ tunDnsAddress ];
      networkmanager = {
        dns = "none";
      };
      # The system stack NATs TCP to tunDnsAddress into a new inbound
      # connection on the tun (random port), which the firewall dropped:
      # DNS over TCP timed out and truncated answers never resolved.
      firewall = {
        trustedInterfaces = [ tunInterface ];
      };
    };

    services = {
      sing-box = {
        enable = true;

        settings = {
          # info logs every DNS answer and connection — browsing history in
          # the persistent journal.
          log.level = "warn";

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
                # Canary domain: NXDOMAIN tells apps with automatic DoH
                # (Firefox rollout) to keep using the system resolver.
                domain = [ "use-application-dns.net" ];
                action = "predefined";
                rcode = "NXDOMAIN";
              }
              {
                # HTTPS/SVCB records can contain real IP hints. Browsers may
                # use them for QUIC and bypass the FakeIP route entirely.
                domain_suffix = proxyDomains;
                query_type = [ "HTTPS" ];
                action = "predefined";
                rcode = "NOERROR";
              }
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
              interface_name = tunInterface;
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
                # transport is WebSocket over TLS/TCP — ALPN must be http/1.1.
                # h3 (from the URI) is for QUIC and makes the server reject
                # with "tls: no application protocol".
                alpn = [ "http/1.1" ];

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
            cache_file = {
              enabled = true;
              store_fakeip = true;
            };
          };
        };
      };
    };

    systemd = {
      services = {
        sing-box = {
          after = lib.mkForce [
            "network.target"
            "nss-lookup.target"
          ];
          requires = lib.mkForce [ ];
          unitConfig = {
            Requires = lib.mkForce [ ];
          };
        };
      };
    };
  };
}
