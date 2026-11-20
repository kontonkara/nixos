{ config, lib, pkgs, username, ... }:

let
  cfg = config.modules.programs.yandex-vpn;

  pkcs11 = pkgs.callPackage ../../../pkgs/jacarta-pkcs11 { };
  provider = "${pkcs11}/lib/libjcPKCS11-2.so";
  openvpn = pkgs.openvpn.override { pkcs11Support = true; };

  # A distinctive name rather than tun0, like sing-box's sing0: the DNS rule
  # below matches on it.
  interface = "yavpn";

  # The zones the office resolver answers while the tunnel is up.
  domains = [
    "yandex-team.ru"
    "yandex.net"
    "yndx.net"
    "yandex.ru"
  ];

  # The token's device unit, under a fixed name from the udev rule below.
  token = "sys-subsystem-usb-devices-jacarta.device";
  # OpenVPN asks for the PIN here; yavpn-agent answers from the session.
  socket = "/run/yavpn/management";

  # The protocol that last brought the tunnel up, tried first next time.
  state = "/var/lib/yavpn/protocol";

  # The connection profiles (servers, CA, tls-auth, the route to the office
  # resolver) are the official setup script's UDP (1199) and TCP (443) ones,
  # kept in sops. Their tls-auth keys differ, so each is its own OpenVPN run.
  # The profile comes first so that the lines after it win: the interface
  # name and the token library. The certificate is picked at connect time.
  profiles = lib.mapAttrs (
    protocol: secret:
    pkgs.writeText "yavpn-${protocol}.conf" ''
      # An option of Yandex's patched build, in the TCP profile.
      ignore-unknown-option yandex-client
      config ${config.sops.secrets.${secret}.path}
      dev ${interface}
      dev-type tun
      pkcs11-providers ${provider}
      # The socket is created world-writable; OpenVPN itself turns away anyone
      # but this user.
      management ${socket} unix
      management-client-user ${username}
      management-query-passwords
      # One pass over the servers, then yavpn-start tries the other protocol:
      # on 2026-11-20 UDP went unanswered for hours while TCP worked.
      connect-retry-max 1
      script-security 2
      route-up "${pkgs.writeShellScript "yavpn-remember" ''echo "$1" > ${state}''} ${protocol}"
    ''
  ) {
    udp = "yandex-vpn/profile";
    tcp = "yandex-vpn/profile-tcp";
  };

  start = pkgs.writeShellApplication {
    name = "yavpn-start";
    runtimeInputs = [
      openvpn
      pkgs.coreutils
      pkgs.gawk
    ];
    text = ''
      # libjcPKCS11-2.so runs unpatched (see its package): it finds
      # libpcsclite and its own siblings there.
      export LD_LIBRARY_PATH=${pkcs11}/lib

      # The token's first certificate, as the official script picks it. pcscd
      # takes a moment to see a token that was just plugged in.
      id=
      for _ in $(seq 20); do
        id=$(openvpn --show-pkcs11-ids ${provider} | awk -F': *' '/Serialized id/ { print $2; exit }' || true)
        if [ -n "$id" ]; then
          break
        fi
        sleep 0.5
      done
      if [ -z "$id" ]; then
        echo "yavpn: no certificate found on the token" >&2
        exit 1
      fi

      # The protocol that worked last, then the other one after each run that
      # ends (a pass over the servers with no answer). The PIN is asked again
      # by the new run. yavpn-agent stops the unit itself after wrong PINs.
      protocol=$(cat ${state} 2>/dev/null || echo udp)
      while true; do
        case $protocol in
          tcp) profile=${profiles.tcp} ;;
          *) profile=${profiles.udp} ;;
        esac
        echo "yavpn: trying $protocol"
        openvpn --config "$profile" --pkcs11-id "$id" || true
        if [ "$protocol" = tcp ]; then protocol=udp; else protocol=tcp; fi
      done
    '';
  };

  agent = pkgs.writeShellApplication {
    name = "yavpn-agent";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.libnotify
      pkgs.socat
      pkgs.systemd
      pkgs.zenity
    ];
    text = ''
      title="Office VPN"

      notify() {
        notify-send --app-name "$title" --icon network-vpn "$@" || true
      }

      # A string for OpenVPN's management commands: in double quotes, with
      # backslashes and quotes escaped.
      quote() {
        local s=''${1//\\/\\\\}
        printf '"%s"' "''${s//\"/\\\"}"
      }

      # The whole unit, not only this OpenVPN run: yavpn-start would start the
      # other protocol, which asks for the PIN again.
      stop() {
        systemctl stop --no-block yavpn.service || echo "signal SIGTERM"
      }

      # One connection to the management socket: stdin and stdout are the
      # socket. Wrong PINs bring the same request back; after three the
      # tunnel is stopped rather than locking the token.
      session() {
        local line type text pin asked=0 connected=false
        echo "state on"
        while IFS= read -r line; do
          line=''${line%$'\r'}
          case $line in
            ">PASSWORD:Need '"*"' password")
              type=''${line#">PASSWORD:Need '"}
              type=''${type%"' password"}
              asked=$((asked + 1))
              if [ "$asked" -gt 3 ]; then
                stop
                notify --urgency critical "Stopped after 3 wrong PINs" "yavpn up tries again."
                continue
              fi
              text="PIN for ''${type%" token"}:"
              if [ "$asked" -gt 1 ]; then
                text="Wrong PIN. The token locks after a few in a row."$'\n\n'"$text"
              fi
              if pin=$(zenity --entry --hide-text --title "$title" --text "$text"); then
                echo "password $(quote "$type") $(quote "$pin")"
              else
                stop
              fi
              pin=
              ;;
            ">STATE:"*",CONNECTED,SUCCESS,"*)
              connected=true
              asked=0
              notify "Connected" "$(echo "$line" | cut -d, -f4)"
              ;;
            ">STATE:"*",RECONNECTING,"*)
              if $connected; then
                notify --urgency low "Reconnecting"
              fi
              ;;
          esac
        done
        if $connected; then
          notify "Disconnected"
        fi
      }

      if [ "''${1:-}" = --session ]; then
        session
        exit 0
      fi

      # The socket exists while yavpn.service runs (from plugging the token
      # in to pulling it out).
      while true; do
        if [ -S ${socket} ]; then
          socat UNIX-CONNECT:${socket} EXEC:"$0 --session" || true
        fi
        sleep 1
      done
    '';
  };

  yavpn = pkgs.writeShellApplication {
    name = "yavpn";
    runtimeInputs = [ pkgs.systemd ];
    text = ''
      case ''${1:-status} in
        up)
          # Without the token the start would wait for its device unit.
          if ! systemctl is-active --quiet ${token}; then
            echo "yavpn: plug the token in" >&2
            exit 1
          fi
          systemctl start yavpn.service
          ;;
        down) systemctl stop yavpn.service ;;
        status) systemctl status yavpn.service ;;
        log) journalctl --unit yavpn.service --follow ;;
        *)
          echo "usage: yavpn [up|down|status|log]" >&2
          exit 2
          ;;
      esac
    '';
  };
in
{
  options = {
    modules = {
      programs = {
        yandex-vpn = {
          enable = lib.mkEnableOption "the office VPN on a JaCarta token (yavpn)";
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    sops = {
      secrets = {
        "yandex-vpn/profile" = { };
        "yandex-vpn/profile-tcp" = { };
        "yandex-vpn/dns" = {
          restartUnits = [ "sing-box.service" ];
        };
      };
    };

    services = {
      # The token is a CCID reader; nixpkgs' ccid driver knows it.
      pcscd = {
        enable = true;
      };

      # Plugging the token in starts the tunnel. The alias gives its device
      # unit a fixed name, which yavpn.service is bound to.
      udev = {
        extraRules = ''
          ACTION!="remove", SUBSYSTEM=="usb", ENV{DEVTYPE}=="usb_device", ATTR{idVendor}=="24dc", ATTR{idProduct}=="0101", TAG+="systemd", ENV{SYSTEMD_ALIAS}+="/sys/subsystem/usb/devices/jacarta", ENV{SYSTEMD_WANTS}+="yavpn.service"
        '';
      };

      # The profile's "dhcp-option DNS" does nothing on Linux without a
      # script. Instead sing-box sends the office zones to the office
      # resolver, through the tunnel, while the interface has an address;
      # otherwise they resolve as before.
      sing-box = lib.mkIf config.modules.system.services.sing-box.enable {
        settings = {
          dns = {
            servers = [
              {
                type = "udp";
                tag = "dns-office";
                server._secret = config.sops.secrets."yandex-vpn/dns".path;
                bind_interface = interface;
              }
            ];

            rules = lib.mkAfter [
              {
                interface_address = {
                  ${interface} = [ "0.0.0.0/0" ];
                };
                domain_suffix = domains;
                # AAAA too: many office hosts are IPv6 only, and the tunnel
                # carries their routes. This rule comes before sing-box's
                # catch-all that answers AAAA empty.
                server = "dns-office";
              }
            ];
          };
        };
      };
    };

    systemd = {
      services = {
        yavpn = {
          description = "Office VPN on the JaCarta token";
          # Pulling the token out stops it.
          bindsTo = [ token ];
          after = [
            token
            "network-online.target"
            "pcscd.socket"
          ];
          wants = [ "network-online.target" ];
          serviceConfig = {
            ExecStart = lib.getExe start;
            RuntimeDirectory = "yavpn";
            RuntimeDirectoryMode = "0755";
            StateDirectory = "yavpn";
            Restart = "on-failure";
            RestartSec = "5s";
          };
        };
      };

      user = {
        services = {
          yavpn-agent = {
            description = "PIN prompt and notifications for the office VPN";
            wantedBy = [ "graphical-session.target" ];
            partOf = [ "graphical-session.target" ];
            after = [ "graphical-session.target" ];
            unitConfig = {
              ConditionUser = username;
            };
            serviceConfig = {
              ExecStart = lib.getExe agent;
              Restart = "on-failure";
            };
          };
        };
      };
    };

    # yavpn up/down without sudo.
    security = {
      polkit = {
        extraConfig = ''
          polkit.addRule(function (action, subject) {
            if (action.id == "org.freedesktop.systemd1.manage-units" &&
                action.lookup("unit") == "yavpn.service" &&
                subject.user == "${username}") {
              return polkit.Result.YES;
            }
          });
        '';
      };
    };

    environment = {
      systemPackages = [ yavpn ];
    };
  };
}
