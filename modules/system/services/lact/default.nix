{ config, lib, ... }:

let
  cfg = config.modules.system.services.lact;
in
{
  options = {
    modules = {
      system = {
        services = {
          lact = {
            enable = lib.mkEnableOption "LACT GPU monitoring and control daemon";
          };
        };
      };
    };
  };

  # No settings here yet: the GUI writes /etc/lact/config.yaml, which turns
  # into a read-only store link once services.lact.settings is set.
  config = lib.mkIf cfg.enable {
    services = {
      lact = {
        enable = true;
      };
    };
  };
}
