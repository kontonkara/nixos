{ config, lib, username, ... }:

let
  cfg = config.modules.home.kitty;

  hmConfig = config.home-manager.users.${username};
  hmStylix = hmConfig.stylix;
  colors = hmConfig.lib.stylix.colors.withHashtag;
  accent = colors.${config.modules.home.stylix.accent};
in
{
  options = {
    modules = {
      home = {
        kitty = {
          enable = lib.mkEnableOption "kitty terminal";
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    home-manager = {
      users = {
        ${username} = {
          programs = {
            kitty = {
              enable = true;
              enableGitIntegration = true;
              shellIntegration = {
                enableFishIntegration = true;
              };

              settings = {
                force_ltr = true;
                open_url_with = "firefox";
                copy_on_select = true;
                hide_window_decorations = true;
                # Yazi's window (Mod+E) has no shell prompt, so -1 would ask
                # on every close.
                confirm_os_window_close = 0;
                enable_audio_bell = false;

                # The 10 ms default caps redraws (output, pixel and momentum
                # scrolling) at ~100 fps; frame callbacks (sync_to_monitor)
                # still pace them to the 240 Hz panel.
                repaint_delay = 4;
                # kitty's documented low-latency value; 3 ms is most of a
                # 4.2 ms frame.
                input_delay = 0;
                # No input method runs (plain xkb us,ru), and kitty's IME
                # support adds latency to the input loop.
                wayland_enable_ime = false;

                # A live line costs 32 bytes per cell (~9 KB at full width);
                # older output goes to the pager buffer (kitty_mod+h) as
                # text, which grows on demand.
                scrollback_lines = 10000;
                scrollback_pager_history_size = 32;

                # Only for cursors that rested 3 ms, so TUI redraws don't
                # leave trails.
                cursor_trail = 3;

                tab_bar_style = "powerline";
                tab_powerline_style = "round";
              };

              # Same fallback as kitty's own maps, or they stop firing on the
              # ru layout.
              keybindings = {
                "--allow-fallback=shifted,ascii kitty_mod+t" = "new_tab_with_cwd";
                "--allow-fallback=shifted,ascii kitty_mod+n" = "new_os_window_with_cwd";
                "kitty_mod+enter" = "new_window_with_cwd";
              };

              # The accent on the active tab and window border, as Catppuccin's
              # kitty theme does. After stylix's include, which sets them from
              # base00 and base03; settings would land before it.
              extraConfig = lib.mkIf (hmStylix.enable && hmStylix.targets.kitty.enable) (
                lib.mkAfter ''
                  active_tab_foreground ${colors.base00}
                  active_tab_background ${accent}
                  active_border_color ${accent}
                ''
              );
            };
          };
        };
      };
    };
  };
}
