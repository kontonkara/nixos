{
  config,
  lib,
  username,
  ...
}:

let
  cfg = config.modules.programs.firefox;
in
{
  options = {
    modules = {
      programs = {
        firefox = {
          enable = lib.mkEnableOption "Firefox";
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    programs.firefox.enable = true;

    home-manager.users.${username}.programs.firefox = {
      enable = true;

      profiles.${username} = {
        id = 0;
        isDefault = true;
        name = username;
        path = username;

        settings = {
          "browser.startup.page" = 3;
          "browser.toolbars.bookmarks.visibility" = "never";

          "browser.search.suggest.enabled" = false;
          "browser.urlbar.showSearchSuggestionsFirst" = false;
          "browser.urlbar.suggest.bookmark" = false;
          "browser.urlbar.suggest.engines" = false;
          "browser.urlbar.suggest.history" = false;
          "browser.urlbar.suggest.openpage" = false;
          "browser.urlbar.suggest.recentsearches" = false;
          "browser.urlbar.suggest.searches" = false;
          "browser.urlbar.suggest.topsites" = false;
          "browser.urlbar.suggest.trending" = false;

          "browser.newtabpage.activity-stream.showSponsored" = false;
          "browser.newtabpage.activity-stream.showSponsoredTopSites" = false;

          "privacy.donottrackheader.enabled" = true;
          "privacy.globalprivacycontrol.enabled" = true;

          "extensions.formautofill.creditCards.enabled" = false;
          "signon.autofillForms" = false;
          "signon.generation.enabled" = false;
          "signon.rememberSignons" = false;
        };
      };

      languagePacks = [
        "en-US"
        "ru-RU"
      ];

      policies = {
        DefaultDownloadDirectory = "\${home}/downloads";
        DisableFirefoxStudies = true;
        DisablePocket = true;
        DisableTelemetry = true;
        EnableTrackingProtection = {
          Value = true;
          Locked = false;
          Cryptomining = true;
          EmailTracking = true;
          Fingerprinting = true;
          Category = "standard";
        };
        NetworkPrediction = false;

        ExtensionSettings."uBlock0@raymondhill.net" = {
          default_area = "menupanel";
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi";
          installation_mode = "force_installed";
          private_browsing = true;
        };
      };
    };
  };
}
