{ config, lib, pkgs, ... }:

let
  cfg = config.modules.system.locale;
in
{
  options = {
    modules = {
      system = {
        locale = {
          enable = lib.mkEnableOption "locale and timezone configuration";
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    console = {
      # 16x32 with Cyrillic: Lat2-Terminus16 is tiny on the 1440p panel
      # (ly draws on the VT too) and has no Cyrillic glyphs.
      packages = [ pkgs.terminus_font ];
      font = "ter-v32n";
      earlySetup = true;
      useXkbConfig = true;
    };
    time = {
      timeZone = "Europe/Minsk";
    };
    i18n = {
      defaultLocale = "en_US.UTF-8";
      # supportedLocales is deprecated; the default locale is added implicitly.
      extraLocales = [
        "ru_RU.UTF-8/UTF-8"
      ];
      # English UI, but 24h clock / Monday-first weeks (noctalia's calendar
      # reads LC_TIME), A4 and metric units. Named locales get generated too.
      extraLocaleSettings = {
        LC_TIME = "en_GB.UTF-8";
        LC_PAPER = "en_GB.UTF-8";
        LC_MEASUREMENT = "en_GB.UTF-8";
      };
    };
  };
}
