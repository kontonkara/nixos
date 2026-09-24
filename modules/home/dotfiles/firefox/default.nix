{ config, lib, username, ... }:

let
  cfg = config.modules.home.firefox;
in
{
  options = {
    modules = {
      home = {
        firefox = {
          enable = lib.mkEnableOption "Firefox web browser";
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    home-manager = {
      users = {
        ${username} = {
          programs = {
            firefox = {
              enable = true;

              profiles.${username} = {
                id = 0;
                isDefault = true;
                name = username;
                path = username;

                settings = {
                  "browser.startup.page" = 3;
                  "browser.toolbars.bookmarks.visibility" = "never";
                  "browser.tabs.dragDrop.createGroup.enabled" = false;
                  "media.videocontrols.picture-in-picture.enable-when-switching-tabs.enabled" = true;

                  # Enable extensions Nix drops into the profile (stylix's
                  # Firefox Color) instead of waiting for about:addons.
                  "extensions.autoDisableScopes" = 0;
                  # Scan the profile's extensions directory (SCOPE_PROFILE) at
                  # startup too. Otherwise only the sideload check after
                  # startup finds an extension a switch added, and it enables
                  # the extension without starting it until the next restart.
                  "extensions.startupScanScopes" = 1;

                  # Spring-damper wheel scrolling, on by default only in
                  # Nightly; smoother on the 240 Hz panel.
                  "general.smoothScroll.msdPhysics.enabled" = true;

                  "browser.search.suggest.enabled" = false;
                  "browser.urlbar.showSearchSuggestionsFirst" = false;
                  "browser.urlbar.showSearchTerms.enabled" = false;
                  "browser.urlbar.suggest.bookmark" = false;
                  "browser.urlbar.suggest.engines" = false;
                  "browser.urlbar.suggest.history" = false;
                  "browser.urlbar.suggest.openpage" = false;
                  "browser.urlbar.suggest.quickactions" = false;
                  "browser.urlbar.suggest.recentsearches" = false;
                  "browser.urlbar.suggest.searches" = false;
                  "browser.urlbar.suggest.topsites" = false;
                  "browser.urlbar.suggest.trending" = false;

                  "privacy.donottrackheader.enabled" = true;
                  "privacy.globalprivacycontrol.enabled" = true;
                  # Strips known tracking parameters in normal windows too, as
                  # Strict mode does.
                  "privacy.query_stripping.enabled" = true;

                  # The NetworkPrediction policy only covers DNS prefetch.
                  "network.prefetch-next" = false;
                  "network.http.speculative-parallel-limit" = 0;

                  "extensions.formautofill.addresses.enabled" = false;
                  "extensions.formautofill.creditCards.enabled" = false;
                  "signon.autofillForms" = false;
                  "signon.generation.enabled" = false;
                  "signon.rememberSignons" = false;
                };
              };

              languagePacks = [
                "en-US"
                "ru"
              ];

              # No DisableFirefoxAccounts: the profile syncs through a Mozilla
              # account.
              policies = {
                # Blocks the sidebar chatbot, link previews, smart tab groups,
                # PDF alt text and smart windows; local translations stay.
                AIControls = {
                  Default = {
                    Value = "blocked";
                  };
                  Translations = {
                    Value = "available";
                  };
                };
                DefaultDownloadDirectory = "\${home}/downloads";
                DisableFirefoxStudies = true;
                DisablePocket = true;
                DisableTelemetry = true;
                # DoH would resolve proxied domains to real IPs and skip the
                # sing-box fakeip route.
                DNSOverHTTPS = {
                  Enabled = false;
                  Locked = true;
                };
                # No Category: it locks the category and makes Firefox ignore
                # every other key here.
                EnableTrackingProtection = {
                  Value = true;
                  Locked = false;
                  Cryptomining = true;
                  EmailTracking = true;
                  Fingerprinting = true;
                };
                FirefoxHome = {
                  TopSites = false;
                  SponsoredTopSites = false;
                  Highlights = false;
                  SponsoredStories = false;
                };
                NetworkPrediction = false;
                SearchEngines = {
                  Default = "Google";
                  Remove = [
                    "Bing"
                    "DuckDuckGo"
                    "Perplexity"
                    "Википедия (ru)"
                  ];
                };
                UserMessaging = {
                  SkipOnboarding = true;
                  MoreFromMozilla = false;
                };

                ExtensionSettings = {
                  "uBlock0@raymondhill.net" = {
                    default_area = "menupanel";
                    install_url = "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi";
                    installation_mode = "force_installed";
                    private_browsing = true;
                  };
                  "ru@dictionaries.addons.mozilla.org" = {
                    install_url = "https://addons.mozilla.org/firefox/downloads/latest/russian-spellchecking-dic-3703/latest.xpi";
                    installation_mode = "force_installed";
                  };
                };
              };
            };
          };
        };
      };
    };
  };
}
