{
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
}
