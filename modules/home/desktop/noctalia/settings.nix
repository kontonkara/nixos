# Complete Noctalia 5.1.0 settings (programs.noctalia.settings, rendered to
# ~/.config/noctalia/config.toml).
#
# Every key of `noctalia config export full` is spelled out here with its
# current effective value, in the export's order (sections and keys sorted
# alphabetically, sub-tables after plain keys), so the whole shell can be tuned
# in one place. Since every value is pinned, changes to Noctalia's built-in
# defaults in later releases no longer apply on their own.
#
# Comment conventions:
#   "CHANGED (default: X)"  the value deviates from Noctalia's built-in
#                           default X; any other value is the built-in default.
#   "set by stylix"         the key comes from stylix's noctalia target
#                           (modules/home/desktop/stylix) and must not be set
#                           here; the comment gives its current value and
#                           Noctalia's default.
#   "optional, unset"       keys that exist but are only exported once set.
#   Ranges are the values the parser clamps to; "UI" marks a narrower range
#   offered by the Settings window.
#   Colors take a palette role (primary, on_primary, secondary, on_secondary,
#   tertiary, on_tertiary, error, on_error, surface, on_surface,
#   surface_variant, on_surface_variant, outline, shadow, hover, on_hover) or
#   a "#RRGGBB" hex value.
#
# Changes made in the Settings window are saved to
# ~/.local/state/noctalia/settings.toml, which overrides this file.
{ pkgs }:

{
  # ── [accessibility] ──────────────────────────────────────────────────────
  accessibility = {
    high_contrast = false; # push surface and background colors toward extremes
    ui_scale = 1.0; # scale of panels and other non-bar UI; 0.5–2.5
  };

  # ── [audio] ──────────────────────────────────────────────────────────────
  audio = {
    enable_overdrive = false; # allow volume above 100% (up to 150%)
    enable_sounds = true; # CHANGED (default: false) master switch for UI sound effects
    notification_sound = ""; # sound file for notifications; "" = bundled notification.wav
    sound_volume = 0.25; # CHANGED (default: 0.5) UI sound volume; 0.0–1.0
    volume_change_sound = ""; # sound file for volume feedback; "" = bundled volume-change.wav
  };

  # ── [backdrop] ───────────────────────────────────────────────────────────
  # Blurred wallpaper copy that niri places in the overview backdrop
  # (layer rule in niri/rules.nix).
  backdrop = {
    blur_intensity = 0.4; # CHANGED (default: 0.5) blur amount; 0.0–1.0
    enabled = true; # CHANGED (default: false) draw the noctalia-backdrop layer
    tint_intensity = 0.6; # CHANGED (default: 0.3) surface-color tint; 0.0–1.0
  };

  # ── [bar] ────────────────────────────────────────────────────────────────
  bar = {
    order = [ "main" ]; # CHANGED (default: [ "default" ]) creation order of the named bars below

    # The built-in bar is called "default"; declaring "main" replaces it, and
    # the CHANGED notes compare against the built-in bar's values.
    # Optional, unset: actions (gesture -> action map for all widgets),
    # font_family, color, icon_color, capsule_foreground, capsule_radius,
    # capsule_border, monitor.<name> (per-output overrides of these keys).
    main = {
      auto_hide = false; # slide out when the pointer leaves; reveal at the screen edge
      background_opacity = 0.93; # CHANGED (default: 1.0) 0.0–1.0
      border = "outline"; # outline color; drawn only when border_width > 0
      border_width = 0.0; # inside outline width in px, 0 = off; 0–20
      capsule = false; # wrap every widget in a capsule unless the widget sets capsule = false
      capsule_fill = "surface_variant"; # capsule background color
      capsule_group = [ ]; # shared capsules { id, members, fill, padding, opacity, accordion, … }, used as "group:<id>" in a lane
      capsule_opacity = 1.0; # capsule background opacity; 0.0–1.0
      capsule_padding = 6.0; # padding inside capsules in px, before scale; 0–48
      capsule_radius = 4.0; # CHANGED (default: unset = pill, half the capsule height) capsule, workspace pill and hover highlight corner radius in px, as the bar's radius; 0 = square; 0–80
      capsule_thickness = 0.76; # capsule size across the bar, fraction of thickness; 0.1–1.0
      center = [
        "clock"
      ]; # center lane: [widget.*] names or built-in widget types
      concave_edge_corners = true; # carve concave notches into two corners; needs margin_edge = 0
      contact_shadow = false; # dark gradient where an attached panel meets the bar
      enabled = true; # show this bar
      end = [
        "tray"
        "notifications"
        "clipboard"
        "battery"
        "volume"
        "brightness"
        "control-center"
      ]; # CHANGED (default: media tray notifications clipboard network bluetooth volume brightness battery control-center session) end (right/bottom) lane
      font_scale = 1.0; # text-only scale on top of scale; 0.2–2.5
      font_weight = 500; # label weight, CSS 100–1000
      hover_highlight = true; # tint the widget under the pointer with its foreground color
      layer = "top"; # top | overlay (above fullscreen windows); attached panels follow
      margin_edge = 4; # CHANGED (default: 0) gap to the screen edge in px; > 0 floats the bar
      margin_ends = 4; # CHANGED (default: 100) inset from both ends in px; 0 = full width
      margin_opposite_edge = 0; # extra reserved space on the inner side in px (for windows ignoring the exclusive zone)
      padding = 14; # padding from the bar ends to the start/end lanes in px; UI 0–80
      panel_overlap = 1; # px an attached panel overlaps the bar to hide the seam; -2–3
      position = "top"; # top | bottom | left | right
      # radius seeds all four corners, but the explicit radius_* keys below win:
      # change them together.
      radius = 4; # CHANGED (default: 12) corner radius in px; 0–500
      radius_bottom_left = 4; # CHANGED (default: 12) 0–500
      radius_bottom_right = 4; # CHANGED (default: 12) 0–500
      radius_top_left = 4; # CHANGED (default: 12) 0–500
      radius_top_right = 4; # CHANGED (default: 12) 0–500
      reserve_space = true; # reserve an exclusive zone so windows don't cover the bar
      scale = 1.0; # content scale (icons, spacing, text); 0.5–4.0
      shadow = true; # cast the global [shell.shadow]
      show_on_workspace_switch = true; # with auto hide: briefly reveal on a workspace change
      smart_auto_hide = false; # hide while the workspace has windows, show it when empty
      start = [
        "workspaces"
        "active_window"
        "media"
      ]; # CHANGED (default: launcher wallpaper workspaces) start (left/top) lane
      thickness = 34; # bar height (width when vertical) in px; 10–300, UI 10–120
      widget_spacing = 6; # gap between widgets in px; UI 0–32

      # Gesture -> action map for bar areas no widget covers, e.g.
      # actions = { left = "panel-toggle launcher"; scroll_up = "volume-up"; };
      # empty = built-in behavior.
      dead_zone = { };
    };
  };

  # ── [battery] ────────────────────────────────────────────────────────────
  # Optional, unset: device."<UPower path or name>".warning_threshold.
  battery = {
    warning_threshold = 20; # CHANGED (default: 10) low-battery notification and warning color at/below this %, 0 = off; 0–100
  };

  # ── [brightness] ─────────────────────────────────────────────────────────
  # Optional, unset: monitor.<connector> = { backend (auto | none | backlight |
  # ddcutil), backlight_device, ddc_bus }.
  brightness = {
    enable_ddcutil = false; # control external monitors over DDC/CI (ddcutil)
    ignore_mmids = [ ]; # ddcutil model ids to skip, e.g. "ACI-ROG_PG279Q-10220"
    minimum_brightness = 0.01; # CHANGED (default: 0.0) floor brightness never drops below; 0.0–1.0
    sync_all_monitors = false; # keep every display at the same brightness
  };

  # ── [calendar] ───────────────────────────────────────────────────────────
  # Optional, unset: account.<id> = { type = google | caldav | ics | vdir; … }.
  calendar = {
    enabled = false; # show events from the calendar accounts
    event_date_format = "%A %e %B"; # strftime format above the event list
    event_time_format = "%H:%M"; # strftime format of event times
    refresh_minutes = 15; # sync interval in minutes; 5–240
  };

  # ── [control_center] ─────────────────────────────────────────────────────
  control_center = {
    hidden_tabs = [ "monitor" "calendar" ]; # CHANGED (default: [ ]) tabs to hide: media audio monitor system network bluetooth weather calendar notifications screen-time power
    show_session_button = false; # CHANGED (default: true) session-actions button in the Home header
    show_shortcut_labels = false; # CHANGED (default: true) text labels under the Home shortcut icons
    sidebar = "compact"; # full | compact | none; sidebar on Home / plain open
    sidebar_section = "none"; # CHANGED (default: "compact") full | compact | none; sidebar when opened straight to a tab
    width = 700; # full-sidebar width in px (compact/none scale down from it); 600–1200

    calendar = {
      show_events_card = false; # CHANGED (default: true) event list beside the month grid
      show_week_numbers = false; # ISO 8601 week numbers beside the month grid
    };

    # CHANGED (default: wifi bluetooth caffeine nightlight notification
    # power_profile). Home tab buttons; the Settings editor offers up to six.
    # Types: wifi bluetooth nightlight notification dark_mode caffeine audio
    # mic_mute power_profile media weather system screen_time keyboard_layout
    # screen_recorder wallpaper session clipboard.
    shortcuts = [
      { type = "wifi"; }
      { type = "bluetooth"; }
      { type = "wallpaper"; }
      { type = "notification"; }
      { type = "caffeine"; }
      { type = "nightlight"; }
      # Switches power-profiles-daemon profiles.
      { type = "power_profile"; }
    ];
  };

  # ── [desktop_widgets] ────────────────────────────────────────────────────
  # Widgets are placed in edit mode, which saves them to settings.toml
  # (widget_order and widget.<id> stay unset here).
  desktop_widgets = {
    enabled = false; # CHANGED (default: true) show widgets on the desktop
    schema_version = 2; # layout format version, a migration marker; leave as is

    grid = {
      cell_size = 16; # snap grid cell in px; 8–256
      major_interval = 4; # every Nth grid line is a major line; 1–16
      visible = true; # show the snap grid in edit mode (G toggles it)
    };
  };

  # ── [dock] ───────────────────────────────────────────────────────────────
  dock = {
    active_monitor_only = true; # CHANGED (default: false) only apps/windows of the active monitor
    active_opacity = 1.0; # focused app icon opacity; 0.0–1.0
    active_scale = 1.0; # focused app icon scale; 0.1–1.75
    auto_hide = true; # CHANGED (default: false) slide out when the pointer leaves; reveal at the edge
    # background_opacity: set by stylix (modules/home/desktop/stylix), stylix.opacity.desktop, currently 1.0 (Noctalia default: 0.88); 0.0–1.0
    border = "outline"; # outline color; drawn only when border_width > 0
    border_width = 0.0; # inside outline width in px, 0 = off; 0–20
    concave_edge_corners = true; # carve concave corners on the screen-edge side; needs margin_edge = 0
    cross_axis_padding = 8; # padding between icons and the screen edge in px; 0–100
    enabled = true; # CHANGED (default: false) show the dock
    icon_size = 40; # CHANGED (default: 48) icon size in px before ui_scale; 16–128
    inactive_opacity = 0.85; # unfocused app icon opacity; 0.0–1.0
    inactive_scale = 0.85; # unfocused app icon scale; 0.1–1.0
    item_spacing = 6; # gap between items in px; 0–100
    launcher_custom_image = ""; # image for the launcher button; overrides launcher_icon
    launcher_custom_image_colorize = false; # tint the custom image with the icon color
    launcher_icon = "grid-dots"; # Tabler glyph of the launcher button
    launcher_position = "none"; # none | start | end; launcher button on the dock
    layer = "top"; # top | overlay (above fullscreen windows)
    magnification = true; # magnify icons near the pointer (macOS style)
    magnification_scale = 1.3; # CHANGED (default: 1.45) maximum magnification at the pointer, 1.0 = off; 1.0–2.0
    main_axis_padding = 16; # padding before the first and after the last icon in px; 0–100
    margin_edge = 8; # CHANGED (default: 0) gap to the screen edge in px; > 0 floats the dock; 0–100
    margin_ends = 0; # inset from both ends in px; 0–500
    monitors = [ ]; # connector names that show the dock; empty = all
    pinned = [ ]; # always-shown apps: desktop entry ids, StartupWMClass or names
    position = "bottom"; # top | bottom | left | right
    # radius seeds all four corners, but the explicit radius_* keys below win:
    # change them together.
    radius = 16; # corner radius in px; 0–80
    radius_bottom_left = 8; # CHANGED (default: 16) 0–80
    radius_bottom_right = 8; # CHANGED (default: 16) 0–80
    radius_top_left = 8; # CHANGED (default: 16) 0–80
    radius_top_right = 8; # CHANGED (default: 16) 0–80
    reserve_space = false; # CHANGED (default: true) reserve an exclusive zone so windows don't cover the dock
    shadow = true; # cast the global [shell.shadow]
    show_dots = true; # CHANGED (default: false) running-window dots below the icons
    show_instance_count = true; # badge with the window count when an app has 2+ windows
    show_running = true; # also show running apps that aren't pinned
    smart_auto_hide = false; # hide while the workspace has windows, show it when empty
  };

  # ── [hooks] ──────────────────────────────────────────────────────────────
  # Shell commands run on shell events: a string or a list of strings.
  # Event details arrive in NOCTALIA_* environment variables.
  hooks = {
    battery_charging = [ ]; # battery starts charging
    battery_discharging = [ ]; # battery starts discharging
    battery_percentage_changed = [ ]; # whole battery percentage changes ($NOCTALIA_BATTERY_PERCENT, $NOCTALIA_BATTERY_STATE)
    battery_plugged = [ ]; # battery becomes fully charged / pending charge
    bluetooth_disabled = [ ]; # default Bluetooth adapter powered off
    bluetooth_enabled = [ ]; # default Bluetooth adapter powered on
    colors_changed = [ ]; # palette resolved and templates updated
    logging_out = [ ]; # right before the session panel logs out
    power_profile_changed = [ ]; # power profile changes ($NOCTALIA_POWER_PROFILE, …_PREVIOUS)
    rebooting = [ ]; # right before the session panel reboots
    session_locked = [ ]; # compositor confirms the session lock
    session_unlocked = [ ]; # session leaves the locked state
    shutting_down = [ ]; # right before the session panel shuts down
    started = [ ]; # once after startup, when IPC is ready
    theme_mode_changed = [ ]; # [theme].mode switches between light and dark ($NOCTALIA_THEME_MODE)
    wallpaper_changed = [ ]; # wallpaper applied ($NOCTALIA_WALLPAPER_PATH, $NOCTALIA_WALLPAPER_CONNECTOR)
    wifi_disabled = [ ]; # Wi-Fi radio turned off
    wifi_enabled = [ ]; # Wi-Fi radio turned on
  };

  # ── [hot_corners] ────────────────────────────────────────────────────────
  # Per corner: action = none | launcher | control_center | window_switcher |
  # overview | command; command = the shell command for action = "command".
  hot_corners = {
    delay_ms = 0; # time the pointer must stay in a corner, 0 = immediate; 0–2000 ms
    enabled = false; # trigger actions by pushing the pointer into screen corners

    bottom_left = {
      action = "none";
      command = "";
    };
    bottom_right = {
      action = "none";
      command = "";
    };
    top_left = {
      action = "none";
      command = "";
    };
    top_right = {
      action = "none";
      command = "";
    };
  };

  # ── [idle] ───────────────────────────────────────────────────────────────
  idle = {
    behavior_order = [
      "lock"
      "screen-off"
    ]; # CHANGED (default: lock screen-off lock-and-suspend) evaluation order; unlisted behaviors go last
    pre_action_fade_seconds = 5.0; # CHANGED (default: 2.0) fade to the surface color before an idle action, 0 = none; 0–120 s

    # Idle behaviors ship disabled; declaring any of them replaces the default
    # set, so each needs its full definition. CHANGED: the built-in set also has
    # "lock-and-suspend" (action lock_and_suspend, timeout 900), and all three
    # are disabled by default.
    behavior = {
      lock = {
        action = "lock"; # lock | screen_off | suspend | lock_and_suspend | command
        command = ""; # shell command for action = "command"
        enabled = true; # CHANGED (default: false) behavior active
        locked_timeout = 0.0; # shorter timeout while locked in s, 0 = use timeout
        resume_command = ""; # shell command run when activity resumes
        timeout = 600.0; # idle seconds before it fires (fractions allowed), 0 = off
      };
      "screen-off" = {
        action = "screen_off"; # lock | screen_off | suspend | lock_and_suspend | command
        command = ""; # shell command for action = "command"
        enabled = true; # CHANGED (default: false) behavior active
        locked_timeout = 0.0; # shorter timeout while locked in s, 0 = use timeout
        resume_command = ""; # shell command run when activity resumes
        timeout = 660.0; # idle seconds before it fires (fractions allowed), 0 = off
      };
    };
  };

  # ── [keybinds] ───────────────────────────────────────────────────────────
  # Keys inside the shell's own UI (panels, launcher, dialogs). Each is a list
  # of chords "Mod+Keysym": Ctrl/Shift/Alt/Super plus an XKB keysym name.
  keybinds = {
    cancel = [ "Escape" ]; # close popups, dismiss panels, abort
    copy = [ "Ctrl+c" ]; # copy the selection or item
    delete = [ "Delete" ]; # delete the selected item
    down = [ "Down" ]; # move focus/selection down
    left = [ "Left" ]; # move focus/selection left
    right = [ "Right" ]; # move focus/selection right
    save = [ "Ctrl+s" ]; # save the selection or item
    tab_next = [ "Tab" ]; # focus the next control
    tab_previous = [ "Shift+ISO_Left_Tab" ]; # focus the previous control
    up = [ "Up" ]; # move focus/selection up
    validate = [
      "Return"
      "KP_Enter"
      "space"
    ]; # confirm, submit, activate the focused item
  };

  # ── [location] ───────────────────────────────────────────────────────────
  # Feeds weather, night light and the auto theme mode.
  # Optional, unset: latitude, longitude (used when auto_locate and address are off).
  location = {
    address = "Vitebsk, Belarus"; # CHANGED (default: "") city/address geocoded when auto_locate = false
    auto_locate = false; # locate from the IP address (via noctalia.dev)
    custom_schedule = false; # use sunrise/sunset below instead of computing them
    sunrise = ""; # "HH:MM" day start; custom_schedule only
    sunset = ""; # "HH:MM" night start; custom_schedule only
  };

  # ── [lockscreen] ─────────────────────────────────────────────────────────
  lockscreen = {
    allow_empty_password = false; # let Enter submit an empty password (security-key PAM stacks)
    blur_intensity = 0.0; # CHANGED (default: 0.5) background blur; 0.0–1.0
    blurred_desktop = false; # use a desktop snapshot as the background
    enabled = true; # session lock, logind integration and lock actions
    fingerprint = false; # CHANGED (default: true) fprintd unlock alongside the password
    # Locks on logind PrepareForSleep, so lid-close suspend resumes locked.
    lock_before_suspend = true; # lock before sleep (lid close, systemctl suspend, hibernate)
    monitors = [ ]; # connectors that show the lock screen (others stay black); empty = all
    tint_intensity = 0.0; # CHANGED (default: 0.3) surface-color tint; 0.0–1.0
    wallpaper = ""; # background image; "" = the desktop wallpaper
  };

  # ── [lockscreen_widgets] ─────────────────────────────────────────────────
  lockscreen_widgets = {
    enabled = false; # widgets on the lock screen (placed with the layout editor)
    schema_version = 2; # layout format version, a migration marker; leave as is

    grid = {
      cell_size = 16; # snap grid cell in px; 8–256
      major_interval = 4; # every Nth grid line is a major line; 1–16
      visible = true; # show the snap grid in edit mode
    };
  };

  # ── [nightlight] ─────────────────────────────────────────────────────────
  nightlight = {
    enabled = false; # warmer colors at night on the [location] schedule
    force = false; # always apply the night temperature
    temperature_day = 6500; # day color temperature in K; 1000–25000, at least 100 above night
    temperature_night = 4000; # night color temperature in K; 1000–25000
  };

  # ── [notification] ───────────────────────────────────────────────────────
  # Optional, unset: filter.<name> = { match, match_content, show_toast,
  # save_history, play_sound, bypass_dnd, … } and filter_order.
  notification = {
    # background_opacity: set by stylix (modules/home/desktop/stylix), stylix.opacity.popups, currently 1.0 (Noctalia default: 0.97); 0.0–1.0
    border = true; # outline around toasts
    collapse_on_dismiss = true; # slide the other toasts together when one is dismissed
    enable_daemon = true; # own org.freedesktop.Notifications
    history_retention_hours = 0; # drop history older than this, 0 = keep; 0–8760
    keep_dismissed_in_history = false; # CHANGED (default: true) keep dismissed toasts in the history
    layer = "overlay"; # CHANGED (default: "top") top | overlay (above fullscreen windows)
    max_visible = 0; # toasts on screen at once, 0 = as many as fit; 0–20
    monitors = [ ]; # connectors/descriptions that show toasts; empty = all
    offset_x = 20; # horizontal margin from the screen/bar edge in px
    offset_y = 8; # vertical margin from the screen/bar edge in px
    position = "top_right"; # top_right | top_left | top_center | bottom_right | bottom_left | bottom_center
    scale = 1.0; # toast size on top of ui_scale; 0.5–2.5
    show_actions = false; # CHANGED (default: true) action buttons; off = clicking the toast runs its default action
    show_app_name = true; # sender app name in toasts
  };

  # ── [osd] ────────────────────────────────────────────────────────────────
  osd = {
    # background_opacity: set by stylix (modules/home/desktop/stylix), stylix.opacity.popups, currently 1.0 (Noctalia default: 0.97); 0.0–1.0
    border = false; # CHANGED (default: true) outline around OSD popups
    enabled = true; # master switch for all OSD popups
    monitors = [ ]; # connectors that show OSDs; empty = all
    offset_x = 20; # horizontal margin from the screen edge in px; >= 0
    offset_y = 8; # vertical margin from the screen edge in px; >= 0
    orientation = "horizontal"; # horizontal | vertical (volume/brightness sliders)
    position = "bottom_center"; # CHANGED (default: "top_center") top_right | top_left | top_center | bottom_* | center_right | center_left
    position_vertical = "top_right"; # CHANGED (default: "top_center") same values; used when orientation = "vertical"
    scale = 1.0; # OSD size on top of ui_scale; 0.5–2.5

    # Which events show an OSD popup.
    kinds = {
      bluetooth = true; # Bluetooth toggled
      brightness = true; # display brightness changed
      caffeine = true; # idle inhibitor toggled
      dnd = true; # Do Not Disturb toggled
      keyboard_backlight = true; # keyboard backlight level changed
      keyboard_layout = true; # keyboard layout switched
      lock_keys = true; # Caps/Num/Scroll Lock changed
      media = false; # CHANGED (default: true) new track started playing
      nightlight = true; # night light toggled
      power_profile = true; # power profile changed
      privacy = true; # mic/camera/screen-share capture started or stopped
      volume = true; # master switch for the two volume OSDs below
      volume_input = true; # microphone volume changed
      volume_output = true; # speaker volume changed
      wifi = true; # Wi-Fi toggled
    };
  };

  # ── [plugin_settings] ────────────────────────────────────────────────────
  # Per-plugin setting overrides: "<author>/<plugin>" = { <key> = <value>; };
  plugin_settings = { };

  # ── [plugins] ────────────────────────────────────────────────────────────
  plugins = {
    auto_update = "all"; # all | official | none; background git updates at startup and every 6 h
    enabled = [ ]; # active plugin ids "<author>/<plugin>"

    # Where plugins come from; declaring the list replaces the two defaults.
    # kind = git (cloned and updated) | path (read-only local dir, e.g. a store path).
    source = [
      {
        enabled = true; # disabled sources are not scanned
        kind = "git";
        location = "https://github.com/noctalia-dev/official-plugins"; # git URL or local path
        name = "official"; # unique handle (letters, digits, . _ -)
      }
      {
        enabled = true;
        kind = "git";
        location = "https://github.com/noctalia-dev/community-plugins";
        name = "community";
      }
    ];
  };

  # ── [shell] ──────────────────────────────────────────────────────────────
  # Optional, unset: lang (BCP-47/POSIX locale; empty = auto), panel_anchor_bar
  # (bar name panels attach to without a source bar), app_icon_color (color for
  # app_icon_colorize).
  shell = {
    app_icon_colorize = false; # recolor app icons to the palette
    avatar_path = "/home/kontonkara/pictures/.face.webp"; # CHANGED (default: "") avatar image path (cropped/resized automatically)
    button_borders = false; # CHANGED (default: true) outlines around buttons
    card_borders = false; # CHANGED (default: true) outlines around section cards in panels and Settings
    clipboard_auto_paste = "off"; # CHANGED (default: "auto") paste after picking an entry: off | auto | ctrl_v | ctrl_shift_v | shift_insert
    clipboard_confirm_clear_history = true; # ask before clearing history or deleting unpinned entries
    clipboard_enabled = true; # clipboard history, panel and copy/paste integration
    clipboard_history_max_entries = 100; # unpinned history entries kept; 10–10000
    clipboard_image_action_command = ""; # command for image entries: {path} = file, {stdin} = stdin position
    # Selections advertising x-kde-passwordManagerHint (KeePassXC)
    # are never read at all; this additionally stops the shell from
    # re-owning a selection once its source app goes away.
    clipboard_keep_from_closed_apps = false; # CHANGED (default: true) keep the last copy pasteable after its app exits
    corner_radius_scale = 0.25; # CHANGED (default: 1.0) corner radius multiplier, 0 = square; 0.0–2.0
    date_format = "%A, %x"; # default date format (strftime) for UI without its own setting
    disable_mipmaps = false; # startup only: turn off texture mipmaps if downscaled images glitch
    external_ip_enabled = false; # resolve the public IP (api.noctalia.dev) for the network tab
    # font_family: set by stylix (modules/home/desktop/stylix), stylix.fonts.sansSerif.name, currently "Inter" (Noctalia default: "sans-serif")
    input_borders = false; # CHANGED (default: true) outlines around text fields and other inputs
    # Recommended with the systemd service: apps launched from the
    # shell are not killed when the service restarts.
    launch_apps_as_systemd_services = true; # CHANGED (default: false) run launched apps in their own systemd units
    launch_apps_custom_command = ""; # wrapper for launched apps; $CMD = the app command
    niri_overview_type_to_launch_enabled = true; # CHANGED (default: false) open the launcher when typing in the niri overview
    offline_mode = false; # block all outgoing network requests
    password_style = "default"; # password mask: default (filled circles) | random (icons)
    # Replaces niri-flake's polkit-kde agent (disabled in default.nix): same
    # libpolkit-agent-1 underneath, but themed and without Qt portal noise.
    polkit_agent = true; # CHANGED (default: false) — built-in polkit authentication agent
    popup_borders = true; # outlines around popups and dropdowns
    popup_shadows = true; # drop shadows behind popups and dropdowns
    screen_time_enabled = false; # track per-app usage for the Control Center
    settings_show_advanced = true; # show advanced options in Settings by default
    settings_window_translucent = false; # translucent Settings window background
    # The first-run wizard writes a settings.toml that overrides this file.
    setup_wizard_enabled = false; # CHANGED (default: true) first-run wizard while its marker is missing
    shared_gl_context = true; # startup only: share GPU textures across surfaces
    show_location = false; # CHANGED (default: true) location name in weather UI
    telemetry_enabled = false; # anonymous startup ping (version, OS, compositor, …)
    time_format = "{:%H:%M}"; # default time format ({:<strftime>}) for UI without its own setting

    animation = {
      enabled = true; # UI animations
      speed = 1.0; # animation speed multiplier (2.0 = twice as fast); 0.1–4.0
    };

    # Optional, unset: privilege_command (prefix for the greeter sync helper).
    greeter_sync = {
      auto_sync = false; # sync Noctalia Greeter on wallpaper/color/theme/font changes
    };

    # Optional, unset: custom_labels = { "English (US)" = "EN"; } (layout name -> label).
    keyboard_layout = { };

    # Optional, unset: providers.<name> = { prefix, global } (calculator, emoji,
    # session, wallpaper, windows, "<plugin>:<entry>").
    launcher = {
      app_grid = false; # icon grid with labels when results are apps only
      auto_paste = "auto"; # paste after copy activations (calculator, emoji, …): off | auto | ctrl_v | ctrl_shift_v | shift_insert
      categories = false; # CHANGED (default: true) category filters (F6 reveals and cycles them)
      compact = false; # smaller icons and tighter rows
      fetch_exchange_rates = true; # fetch currency rates from online sources
      pinned = [ ]; # desktop entry ids shown first when the launcher opens
      provider_prefix = "/"; # prefix character for provider trigger words ("/calc", …)
      show_app_actions = true; # CHANGED (default: false) also list .desktop actions
      show_app_origin_indicator = true; # package-origin badges on app results
      show_icons = true; # app icons in results
      sort_by_usage = true; # boost frequently used apps, add a Recently Used filter

      # dmenu-style providers: entry.<id> = { command, exec, prefix, label, glyph,
      # global, freeform }; command's stdout lines become results.
      dmenu = { };
    };

    mpris = {
      blacklist = [ ]; # players ignored by media widgets and the Control Center
    };

    # Per-panel placement: attached (to the bar) | floating. *_position applies
    # to floating panels: auto (bar-relative) | center | top_left | top_center |
    # top_right | center_left | center_right | bottom_left | bottom_center |
    # bottom_right. open_near_click_* opens at the clicked widget instead of
    # the bar center.
    panel = {
      borders = false; # CHANGED (default: true) outline on floating panels
      clipboard_placement = "floating"; # attached | floating
      clipboard_position = "center";
      control_center_placement = "floating"; # CHANGED (default: "attached") attached | floating; also the calendar and media panels, which are its tabs
      control_center_position = "auto";
      floating_layer = "top"; # CHANGED (default: "overlay") top | overlay; use top if IME candidate windows end up behind panels
      floating_offset = 8; # gap between a floating panel and the bar in px; 0–100
      launcher_placement = "floating"; # attached | floating
      launcher_position = "center";
      list_item_background = false; # rounded background behind launcher/clipboard list items
      open_near_click_clipboard = false;
      open_near_click_control_center = true; # CHANGED (default: false)
      open_near_click_launcher = false;
      open_near_click_session = false;
      open_near_click_wallpaper = false;
      polkit_placement = "floating"; # attached | floating
      polkit_position = "center";
      session_placement = "floating"; # CHANGED (default: "attached")
      session_position = "center"; # CHANGED (default: "auto")
      shadow = true; # cast the global [shell.shadow] from panels
      transparency_mode = "soft"; # CHANGED (default: "solid") solid | soft | glass; panel and card translucency
      wallpaper_placement = "floating"; # CHANGED (default: "attached")
      wallpaper_position = "center"; # CHANGED (default: "auto")
    };

    # Regexes for apps ignored by the privacy indicators and OSDs.
    privacy = {
      cam_filter_regex = ""; # camera apps
      mic_filter_regex = ""; # microphone apps
      screen_filter_regex = ""; # screen-sharing apps
    };

    screen_corners = {
      enabled = false; # black rounded overlay in the screen corners
      size = 32; # corner radius in px; 1–100
    };

    screenshot = {
      annotate = false; # open the annotation editor before the output actions
      close_on_copy = true; # close the editor after a successful copy
      confirm_region = false; # wait for Enter/Space after selecting a region
      copy_to_clipboard = true; # copy the PNG to the clipboard
      directory = ""; # save folder; "" = XDG Pictures
      filename_pattern = ""; # strftime name without .png; "" = screenshot_%Y%m%d_%H%M%S
      freeze_screen = true; # freeze the desktop while selecting a region
      pipe_command = ""; # command receiving the PNG on stdin, e.g. "satty -f -"
      pipe_to_command = false; # pipe the PNG to pipe_command
      remember_last_region = false; # preselect the previous region
      save_to_file = true; # save the PNG to directory
      show_cursor = false; # include the pointer initially
    };

    session = {
      grid = false; # lay the session actions out in a grid
      grid_columns = 3; # grid columns; 1–5
      show_shortcuts = true; # shortcut hints on the action buttons

      # Optional, unset: suspend, reboot, shutdown (shell commands replacing the
      # built-in power backends).
      power = { };

      # Session panel buttons, in order. Fields: action = lock | logout |
      # suspend | lock_and_suspend | reboot | shutdown | command; command =
      # shell command (replaces the built-in handler; required for "command");
      # countdown_seconds = confirmation countdown in s, 0 = run at once;
      # enabled; glyph = Tabler icon ("" = built-in); label ("" = built-in);
      # shortcut = key chord inside the panel; variant = default | primary |
      # secondary | destructive | outline | ghost.
      # CHANGED: the built-in list is lock, logout, lock_and_suspend, reboot,
      # shutdown (shortcuts 1–5, no countdown), without the UEFI entry.
      actions = [
        {
          action = "lock";
          command = "";
          countdown_seconds = 10.0;
          enabled = true;
          glyph = "";
          label = "";
          shortcut = "1";
          variant = "default";
        }
        {
          # A plain "suspend" started from the shell skips lock_before_suspend.
          action = "lock_and_suspend";
          command = "";
          countdown_seconds = 10.0;
          enabled = true;
          glyph = "";
          label = "";
          shortcut = "2";
          variant = "default";
        }
        {
          action = "reboot";
          command = "";
          countdown_seconds = 10.0;
          enabled = true;
          glyph = "";
          label = "";
          shortcut = "4";
          variant = "default";
        }
        {
          action = "logout";
          command = "";
          countdown_seconds = 10.0;
          enabled = true;
          glyph = "";
          label = "";
          shortcut = "5";
          variant = "default";
        }
        {
          action = "shutdown";
          command = "";
          countdown_seconds = 10.0;
          enabled = true;
          glyph = "";
          label = "";
          shortcut = "6";
          variant = "destructive";
        }
        {
          action = "command";
          command = "systemctl reboot --firmware-setup";
          countdown_seconds = 10.0;
          enabled = true;
          glyph = "cpu";
          label = "Reboot to UEFI";
          shortcut = "7";
          variant = "default";
        }
      ];
    };

    shadow = {
      alpha = 0.5; # CHANGED (default: 0.55) shadow opacity, times each surface's background opacity; 0.0–1.0
      direction = "down"; # center | up | down | left | right | up_left | up_right | down_left | down_right
    };

    window_switcher = {
      mru = false; # order by most recently used instead of workspace/screen layout
    };
  };

  # ── [storage] ────────────────────────────────────────────────────────────
  # Master key of the encrypted private storage (clipboard history, calendar
  # cache).
  storage = {
    key_file = ""; # absolute path to a 64-hex-char key; only with key_source = "file"
    key_source = "secret-service"; # secret-service | file
  };

  # ── [system.monitor] ─────────────────────────────────────────────────────
  # Poll intervals in seconds: 0 disables that metric group, other values are
  # clamped to 1–120. Thresholds: sysmon widgets tint toward their
  # highlight_color from the activity value up to the critical value
  # (critical = 0 disables the highlight).
  system = {
    monitor = {
      cpu_freq_activity_threshold = 2.5; # GHz
      cpu_freq_critical_threshold = 4.5; # GHz
      cpu_poll_seconds = 2.0; # CPU usage, frequency, temperature, load average
      cpu_temp_activity_threshold = 60.0; # °C
      cpu_temp_critical_threshold = 85.0; # °C
      cpu_temp_sensor_path = ""; # exact hwmon temp*_input file; "" = auto (k10temp, zenpower, coretemp)
      cpu_usage_activity_threshold = 50.0; # %
      cpu_usage_critical_threshold = 90.0; # %
      disk_free_activity_threshold = 80.0; # %
      disk_free_critical_threshold = 95.0; # %
      disk_free_pct_activity_threshold = 80.0; # %
      disk_free_pct_critical_threshold = 95.0; # %
      disk_poll_seconds = 10.0; # disk and swap usage
      disk_used_activity_threshold = 80.0; # %
      disk_used_critical_threshold = 95.0; # %
      disk_used_pct_activity_threshold = 80.0; # %
      disk_used_pct_critical_threshold = 95.0; # %
      enabled = false; # CHANGED (default: true) background sampling of CPU, memory, network, temperature and disk stats
      # 0 disables GPU sampling entirely, so NVML never touches the dGPU
      # (the control center's system tab would otherwise poll it).
      gpu_poll_seconds = 0.0; # CHANGED (default: 5.0) GPU temperature, usage, VRAM
      gpu_temp_activity_threshold = 60.0; # °C
      gpu_temp_critical_threshold = 85.0; # °C
      gpu_usage_activity_threshold = 50.0; # %
      gpu_usage_critical_threshold = 95.0; # %
      gpu_vram_activity_threshold = 50.0; # %
      gpu_vram_critical_threshold = 90.0; # %
      memory_poll_seconds = 2.0; # RAM usage
      net_rx_activity_threshold = 1.0; # MB/s
      net_rx_critical_threshold = 50.0; # MB/s
      net_tx_activity_threshold = 1.0; # MB/s
      net_tx_critical_threshold = 50.0; # MB/s
      network_poll_seconds = 3.0; # network throughput
      ram_pct_activity_threshold = 60.0; # % (also used by ram_used)
      ram_pct_critical_threshold = 90.0; # %
      swap_pct_activity_threshold = 20.0; # %
      swap_pct_critical_threshold = 80.0; # %
    };
  };

  # ── [theme] ──────────────────────────────────────────────────────────────
  # Palette (custom "stylix"), dark mode, font and the dock,
  # notification and OSD opacity come from stylix's noctalia target.
  theme = {
    builtin = "Noctalia"; # palette for source = "builtin": Ayu Catppuccin Dracula Eldritch Gruvbox Kanagawa Noctalia Nord "Rosé Pine" Tokyo-Night
    community_palette = "Oxocarbon"; # palette name for source = "community"
    # custom_palette: set by stylix (modules/home/desktop/stylix), currently "stylix" (Noctalia default: ""), i.e. ~/.config/noctalia/palettes/stylix.json
    # mode: set by stylix (modules/home/desktop/stylix) from stylix.polarity, currently "dark" (= Noctalia default); dark | light | auto
    pure_black_dark = false; # true-black dark surfaces (OLED)
    shell_mode = "follow"; # follow | dark | light | auto; Noctalia's own mode, follow = mode
    # source: set by stylix (modules/home/desktop/stylix), currently "custom" (Noctalia default: "builtin"); builtin | wallpaper | community | custom
    wallpaper_scheme = "m3-content"; # for source = "wallpaper": m3-content m3-tonal-spot m3-fruit-salad m3-rainbow m3-monochrome vibrant faithful soft dysfunctional muted

    # Noctalia's own app templates would fight stylix over the same files.
    # Optional, unset: custom_colors, user.<id> (own templates).
    templates = {
      builtin_ids = [ ]; # bundled templates to render (noctalia theme --list-templates)
      community_ids = [ ]; # community templates to render
      enable_builtin_templates = false; # CHANGED (default: true)
      enable_community_templates = false; # CHANGED (default: true)
    };
  };

  # ── [wallpaper] ──────────────────────────────────────────────────────────
  # Optional, unset: monitor.<connector> = { enabled, fill_color, directory,
  # directory_light, directory_dark } (with per_monitor_directories).
  wallpaper = {
    directory = "~/pictures/wallpapers"; # CHANGED (default: "" = XDG Pictures) folder of the wallpaper picker
    directory_dark = ""; # folder used in dark mode; "" = directory
    directory_light = ""; # folder used in light mode; "" = directory
    edge_smoothness = 0.05; # CHANGED (default: 0.3) feathering of transition edges; 0.0–1.0
    enabled = true; # wallpaper service
    fill_color = ""; # color behind the image in uncovered areas; "" = none
    fill_mode = "crop"; # center | crop | fit | stretch | repeat | span
    per_monitor_directories = false; # separate folders per monitor (monitor.<connector>)
    transition = [
      "fade"
    ]; # CHANGED (default: fade wipe disc stripes zoom honeycomb) one picked at random per change; fade wipe disc stripes zoom honeycomb
    transition_duration = 1500.0; # transition length in ms; 100–30000
    transition_on_startup = true; # CHANGED (default: false) animate the first wallpaper at startup; fades in over niri's base00 background instead of popping in

    default = {
      path = "/home/kontonkara/pictures/wallpapers/shadow-shape-holo.jpeg"; # CHANGED (default: "" = none) the wallpaper; per-monitor picks from the picker go to monitors.<connector>.path
    };

    automation = {
      enabled = false; # cycle wallpapers on a timer
      interval_seconds = 1800; # seconds between changes; 1–86400
      order = "random"; # random | alphabetical
      recursive = true; # include subfolders
    };
  };

  # ── [weather] ────────────────────────────────────────────────────────────
  weather = {
    effects = false; # CHANGED (default: true) visual weather effects
    enabled = true; # weather service (open-meteo.com)
    refresh_minutes = 30; # refresh interval in minutes; 5–240
    unit = "metric"; # metric | imperial
  };

  # ── [widget.*] ───────────────────────────────────────────────────────────
  # Named bar widget instances, referenced from the bar lanes; type defaults
  # to the instance name. Common optional keys: enabled, anchor, scale,
  # font_scale, font_family, font_weight, color, icon_color, capsule,
  # capsule_* (as in [bar]), interactive, scroll_repeat, actions = { left,
  # right, middle, scroll_up, … }. Built-in instances that no lane uses
  # (cpu, date, input_volume, …) are kept as the export lists them. Sizes in px.
  widget = {
    # Optional, unset: display (icon_and_text | icon_only | text_only), show_empty_label.
    active_window = {
      enabled = false; # CHANGED (default: true) show this widget
      icon_size = 14.0; # app icon size
      max_length = 145; # CHANGED (default: 260) maximum width
      min_length = 80.0; # minimum width
      title_scroll = "on_hover"; # CHANGED (default: "none") none | always | on_hover
      type = "active_window";
    };

    # Optional, unset: show_label, label_content (percent | time | rate),
    # hide_when_plugged, hide_when_full, device (UPower selector, "auto"), warning_color.
    battery = {
      display_mode = "graphic"; # CHANGED (default: "glyph") none | glyph | graphic (battery shape with fill)
      hide_when_plugged = true; # CHANGED (default: false) hide while on AC power
      type = "battery";
    };

    brightness = {
      show_label = false; # CHANGED (default: true) percentage next to the glyph
      type = "brightness";
    };

    # Optional, unset: vertical_format, timezone (e.g. "Europe/Minsk").
    clock = {
      format = "{:%H:%M %a, %b %d}"; # CHANGED (default: "{:%H:%M}") {:<strftime>}, "\n" for extra lines
      tooltip_format = "{:%H:%M %a, %b %d}"; # CHANGED (default: "" = no tooltip) same syntax as format
      type = "clock";
    };

    # Optional, unset: glyph (default "noctalia"), custom_image_colorize.
    "control-center" = {
      custom_image = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg"; # CHANGED (default: "" = glyph) image instead of the glyph
      custom_image_colorize = true; # CHANGED (default: false) tint the custom image with the widget's icon color
      type = "control-center";
    };

    # sysmon: stat = cpu_usage | cpu_temp | cpu_freq | gpu_temp | gpu_usage |
    # gpu_vram | ram_used | ram_pct | swap_pct | disk_used_pct | disk_used |
    # disk_free_pct | disk_free | net_rx | net_tx. Optional, unset: path,
    # interface, visualization (gauge | graph | none), show_value, glyph,
    # highlight_color, network_speed_unit, …
    cpu = {
      stat = "cpu_usage";
      type = "sysmon";
    };

    date = {
      format = "{:%a %d %b}"; # {:<strftime>}
      type = "clock";
    };

    # volume: device = output | input. Optional, unset: show_label, glyph,
    # mute_glyph, mute_color, hide_when_inactive (input only), …
    input_volume = {
      device = "input";
      type = "volume";
    };

    # Optional, unset: show_glyph, glyph, show_label, display (short | full).
    keyboard_layout = {
      hide_when_single_layout = false; # hide unless more than one layout is configured
      type = "keyboard_layout";
    };

    lock_keys = {
      display = "short"; # short (C N S) | full (Caps Num Scroll)
      hide_when_off = false; # hide each indicator while it is off
      show_caps_lock = true;
      show_num_lock = true;
      show_scroll_lock = false;
      type = "lock_keys";
    };

    # Optional, unset: album_art_only, hide_album_art, hide_artist.
    media = {
      art_size = 16.0; # album art size before scale
      artist_first = true; # CHANGED (default: false) "Artist - Title" instead of "Title - Artist"
      hide_when_no_media = true; # CHANGED (default: false) hide without an active MPRIS player
      max_length = 145; # CHANGED (default: 220) maximum width
      min_length = 80.0; # minimum width
      title_scroll = "on_hover"; # CHANGED (default: "none") none | always | on_hover
      type = "media";
    };

    network_rx = {
      stat = "net_rx";
      type = "sysmon";
    };

    network_tx = {
      stat = "net_tx";
      type = "sysmon";
    };

    notifications = {
      hide_when_no_unread = true; # CHANGED (default: false) hide without unread notifications
      type = "notifications";
    };

    output_volume = {
      device = "output";
      type = "volume";
    };

    ram = {
      stat = "ram_used";
      type = "sysmon";
    };

    # Optional, unset: length (default 8 px).
    spacer = {
      interactive = false; # true = receives hover/clicks (e.g. a hidden hot zone with actions)
      type = "spacer";
    };

    temp = {
      stat = "cpu_temp";
      type = "sysmon";
    };

    # Optional, unset: hidden, pinned, match_adjacent_spacing, drawer_columns,
    # drawer_item_size, detached_panel.
    tray = {
      detached_panel = true; # CHANGED (default: false) open the drawer as a floating panel, not anchored to the bar edge
      drawer = true; # CHANGED (default: false) one tray button opening a drawer instead of inline icons
      hide_passive = false; # CHANGED (default: true) hide items with Passive status
      type = "tray";
    };

    volume = {
      show_label = false; # CHANGED (default: true) percentage next to the glyph
      type = "volume";
    };

    # Optional, unset: style (regular | minimal | focus_hint), show_labels,
    # show_icons, show_all_outputs, pill_scale, active_pill_size,
    # inactive_pill_size, urgent_color, change_color_on_hover, focused_output_only.
    workspaces = {
      empty_color = "secondary"; # empty workspace pills
      focused_color = "primary"; # focused workspace pill
      font_weight = 700; # CHANGED (default: the bar's font_weight, 500) label weight, 100–1000
      hide_when_empty = true; # CHANGED (default: false) hide workspaces without windows
      label_source = "id"; # id (number) | name
      labels_only_when_occupied = true; # CHANGED (default: false) labels only on occupied and active workspaces
      max_label_chars = 2; # CHANGED (default: 1) truncate non-numeric labels; 1–20
      occupied_color = "primary"; # CHANGED (default: "secondary") occupied workspace pills
      type = "workspaces";
    };
  };
}
