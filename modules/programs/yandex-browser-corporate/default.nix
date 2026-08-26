{ config, lib, ... }:

let
  cfg = config.modules.programs.yandex-browser-corporate;
in
{
  options = {
    modules = {
      programs = {
        yandex-browser-corporate = {
          enable = lib.mkEnableOption "Yandex Browser Corporate";
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    programs.yandex-browser-corporate = {
      enable = true;
      passwordStore = "kwallet6";
      forcePortalDownloads = true;
      backgroundModeEnabled = false;
      installFlatpakShim = true;
      extraCommandLineArgs = [ "--enable-wayland-ime" ];
      extraManagedPolicies = {
        MetricsReportingEnabled = false;
        SafeBrowsingExtendedReportingEnabled = false;
        PromotionalTabsEnabled = false;
        DefaultBrowserSettingEnabled = false;
      };

      extraRecommendedPolicies = { };
    };
  };
}
