{ config, lib, ... }:

let
  cfg = config.modules.system.network.iwlwifi;
in
{
  options = {
    modules = {
      system = {
        network = {
          iwlwifi = {
            enable = lib.mkEnableOption "iwlwifi with LAR disabled and a fixed regulatory domain";

            country = lib.mkOption {
              type = lib.types.str;
              default = "US";
              description = "ISO 3166 alpha2 code for cfg80211 once the firmware no longer picks it.";
            };
          };
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    boot = {
      # With LAR on, the AX210 firmware self-manages the regdomain from nearby
      # beacons (lands on BY here) and ignores cfg80211. lar_disable hands
      # regulatory back to the kernel so ieee80211_regdom applies.
      extraModulePackages = [
        (config.boot.kernelPackages.callPackage ../../../../pkgs/iwlwifi-lar { })
      ];

      extraModprobeConfig = ''
        options cfg80211 ieee80211_regdom=${cfg.country}
        options iwlwifi lar_disable=1
      '';
    };
  };
}
