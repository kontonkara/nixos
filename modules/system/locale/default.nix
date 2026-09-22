{ config, lib, ... }:

let
  cfg = config.modules.system.locale;
in
{
  options = {
    modules = {
      system = {
        locale = {
          enable = lib.mkEnableOption "locale, timezone and console font";
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    i18n = {
      defaultLocale = "en_US.UTF-8";
    };

    console = {
      font = "Lat2-Terminus16";
      useXkbConfig = true;
    };

    time = {
      timeZone = "Europe/Minsk";
    };
  };
}
