{ config, lib, username, ... }:

let
  cfg = config.modules.system.services.tailscale;
in
{
  options = {
    modules = {
      system = {
        services = {
          tailscale = {
            enable = lib.mkEnableOption "tailscale mesh vpn";
          };
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    services = {
      tailscale = {
        enable = true;
        # UDP 41641, for direct paths to peers instead of relaying through
        # DERP. Nothing else is opened on tailscale0: the firewall treats it
        # like any other interface.
        openFirewall = true;
        # `tailscale set` after every start of tailscaled, so these hold
        # whatever the one interactive login was run with.
        extraSetFlags = [
          # tailscale up/down/set without sudo.
          "--operator=${username}"
          # sing-box owns DNS (FakeIP for the proxied domains, see its
          # module); MagicDNS would put 100.100.100.100 in front of it.
          # Instead sing-box asks 100.100.100.100 for *.ts.net only.
          "--accept-dns=false"
        ];
      };
    };
  };
}
