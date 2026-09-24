{ config, lib, inputs, username, ... }:

let
  cfg = config.modules.home.spotify;

  spicePkgs = inputs.spicetify-nix.legacyPackages.x86_64-linux;

  hmConfig = config.home-manager.users.${username};
  hmStylix = hmConfig.stylix;
  accent = hmConfig.lib.stylix.colors.${config.modules.home.stylix.accent};
  font = builtins.toJSON hmStylix.fonts.sansSerif.name;

  # Hex of slot a over slot b at pct percent, per sRGB channel.
  mix =
    a: b: pct:
    let
      channel = slot: ch: lib.toInt hmConfig.lib.stylix.colors."${slot}-rgb-${ch}";
      blend = ch: (channel a ch * pct + channel b ch * (100 - pct) + 50) / 100;
    in
    lib.concatMapStrings (ch: lib.fixedWidthString 2 "0" (lib.toLower (lib.toHexString (blend ch)))) [
      "r"
      "g"
      "b"
    ];
in
{
  options = {
    modules = {
      home = {
        spotify = {
          enable = lib.mkEnableOption "spotify patched by spicetify";
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    home-manager = {
      sharedModules = [
        inputs.spicetify-nix.homeManagerModules.default
      ];

      users = {
        ${username} = {
          programs = {
            spicetify = lib.mkMerge [
              {
                enable = true;
                # GPU rendering stays on: with --disable-gpu the CEF renderer
                # drew spicetify's animated extensions on the CPU and froze.
                # Unlike VSCode and Yandex Browser, Spotify never triggered the
                # radeonsi page fault (journal since 2026-09-23).

                # Lyrics go through Lyrics Plus only (enabledCustomApps): no
                # Beautiful Lyrics, whose page the player's button opened
                # while the top bar opened Lyrics Plus.
                enabledExtensions = with spicePkgs.extensions; [
                  adblock
                  {
                    src = ./extensions;
                    name = "lyrics-plus-playbar.js";
                  }
                  coverAmbience
                  fullAlbumDate
                  goToSong
                  hidePodcasts
                  playNext
                  playingSource
                  queueTime
                  shuffle
                  sleepTimer
                  volumePercentage
                ];

                enabledCustomApps = with spicePkgs.apps; [
                  betterLibrary
                  historyInSidebar
                  lyricsPlus
                  newReleases
                ];

                enabledSnippets = with spicePkgs.snippets; [
                  centeredLyrics
                  hideScrollThroughPreviews
                  hideSidebarScrollbar
                  hideWhatsNewButton
                  modernScrollbar
                  removeGradient
                  smoothProgressBar
                ];
              }

              # On top of stylix's spicetify theme: its color.ini paints the
              # buttons and player bar gray (base04) and the equalizer green.
              (lib.mkIf (hmStylix.enable && hmStylix.targets.spicetify.enable) {
                colorScheme = lib.mkForce "custom";
                customColorScheme = with hmConfig.lib.stylix.colors; {
                  text = base05;
                  # base04 is 2.5:1 on base00; this blend is 5.2:1 and stays
                  # below text.
                  subtext = mix "base05" "base00" 62;
                  main = base00;
                  main-elevated = base02;
                  highlight = base02;
                  highlight-elevated = base03;
                  sidebar = base01;
                  player = base01;
                  card = base02;
                  shadow = base00;
                  selected-row = base03;
                  button = accent;
                  button-active = accent;
                  button-disabled = base03;
                  tab-active = base02;
                  notification = base02;
                  notification-error = base08;
                  equalizer = accent;
                  misc = base02;
                };
                theme = {
                  # Spotify's own rules read font-family from these variables;
                  # a body/button rule loses to their class selectors. The
                  # stylix theme is only a color.ini, so minimal.css is the
                  # whole theme; it paints with the --spice-* roles above.
                  additionalCss = ''
                    :root {
                      --encore-body-font-stack: ${font}, sans-serif;
                      --encore-title-font-stack: ${font}, sans-serif;
                      --encore-variable-font-stack: ${font}, sans-serif;
                    }
                  ''
                  + builtins.readFile ./minimal.css;
                };
              })
            ];
          };
        };
      };
    };
  };
}
