{ config, lib, ... }:

let
  cfg = config.modules.locale;
in
{
  options = {
    modules = {
      locale = {
        enable = lib.mkEnableOption "locale and timezone configuration";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    console = {
      font = "Lat2-Terminus16";
      useXkbConfig = true;
    };
    time = {
      timeZone = "Europe/Minsk";
    };
    i18n = {
      defaultLocale = "en_US.UTF-8";
      extraLocaleSettings = {
        LC_TIME = "en_US.UTF-8";
        LC_MONETARY = "en_US.UTF-8";
      };
      supportedLocales = [
        "en_US.UTF-8/UTF-8"
        "ru_RU.UTF-8/UTF-8"
      ];
    };
  };
}
