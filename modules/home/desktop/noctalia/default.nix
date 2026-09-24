{ config, lib, pkgs, username, ... }:

let
  cfg = config.modules.home.noctalia;
in
{
  options = {
    modules = {
      home = {
        noctalia = {
          enable = lib.mkEnableOption "noctalia desktop shell";
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    home-manager = {
      users = {
        ${username} = {
          programs = {
            noctalia = {
              enable = true;
              systemd = {
                enable = true;
              };

              settings = {
                shell = {
                  corner_radius_scale = 0.2;
                  card_borders = false;
                  telemetry_enabled = false;
                  # The first-run wizard writes a settings.toml that overrides this file.
                  setup_wizard_enabled = false;
                  # niri-flake already runs polkit-kde-agent.
                  polkit_agent = false;
                  # Recommended with the systemd service: apps launched from the
                  # shell are not killed when the service restarts.
                  launch_apps_as_systemd_services = true;
                  show_location = false;

                  clipboard_enabled = true;
                  # Selections advertising x-kde-passwordManagerHint (KeePassXC)
                  # are never read at all; this additionally stops the shell from
                  # re-owning a selection once its source app goes away.
                  clipboard_keep_from_closed_apps = false;
                  clipboard_auto_paste = "off";

                  shadow = {
                    direction = "down_right";
                  };

                  panel = {
                    control_center_placement = "floating";
                    wallpaper_placement = "floating";
                    session_placement = "floating";
                    open_near_click_control_center = true;
                    wallpaper_position = "center";
                    session_position = "center";
                  };

                  session = {
                    actions = [
                      {
                        action = "lock";
                        shortcut = "1";
                        countdown_seconds = 10;
                      }
                      {
                        # A plain "suspend" started from the shell skips lock_before_suspend.
                        action = "lock_and_suspend";
                        shortcut = "2";
                        countdown_seconds = 10;
                      }
                      {
                        action = "reboot";
                        shortcut = "4";
                        countdown_seconds = 10;
                      }
                      {
                        action = "logout";
                        shortcut = "5";
                        countdown_seconds = 10;
                      }
                      {
                        action = "shutdown";
                        variant = "destructive";
                        shortcut = "6";
                        countdown_seconds = 10;
                      }
                      {
                        action = "command";
                        label = "Reboot to UEFI";
                        glyph = "cpu";
                        command = "systemctl reboot --firmware-setup";
                        shortcut = "7";
                        countdown_seconds = 10;
                      }
                    ];
                  };
                };

                theme = {
                  mode = "dark";
                  source = "builtin";
                  builtin = "Catppuccin";
                  templates = {
                    enable_builtin_templates = false;
                    enable_community_templates = false;
                  };
                };

                wallpaper = {
                  enabled = true;
                  directory = "~/pictures/wallpapers";
                  fill_mode = "crop";
                  transition = [
                    "fade"
                    "disc"
                    "stripes"
                    "wipe"
                    "honeycomb"
                  ];
                  edge_smoothness = 0.05;
                };

                # Blurred wallpaper copy that niri places in the overview backdrop
                # (layer rule in niri/rules.nix).
                backdrop = {
                  enabled = true;
                  blur_intensity = 0.4;
                  tint_intensity = 0.6;
                };

                lockscreen = {
                  enabled = true;
                  # Locks on logind PrepareForSleep, so lid-close suspend resumes locked.
                  lock_before_suspend = true;
                  fingerprint = false;
                  blur_intensity = 0.0;
                  tint_intensity = 0.0;
                };

                # Idle behaviors ship disabled; declaring any of them replaces the
                # default set, so each needs its full definition.
                idle = {
                  pre_action_fade_seconds = 5.0;
                  behavior = {
                    lock = {
                      enabled = true;
                      timeout = 600;
                      action = "lock";
                    };
                    "screen-off" = {
                      enabled = true;
                      timeout = 660;
                      action = "screen_off";
                    };
                  };
                };

                notification = {
                  position = "top_right";
                  layer = "overlay";
                  background_opacity = 1.0;
                  keep_dismissed_in_history = false;
                };

                osd = {
                  position = "top_right";
                  background_opacity = 1.0;
                  kinds = {
                    keyboard_layout = false;
                    media = false;
                  };
                };

                system = {
                  monitor = {
                    # 0 disables GPU sampling entirely, so NVML never touches the dGPU
                    # (the control center's system tab would otherwise poll it).
                    gpu_poll_seconds = 0;
                  };
                };

                location = {
                  address = "Vitebsk, Belarus";
                };

                weather = {
                  enabled = true;
                  effects = false;
                  unit = "metric";
                };

                brightness = {
                  minimum_brightness = 0.01;
                };

                battery = {
                  warning_threshold = 20;
                };

                control_center = {
                  shortcuts = [
                    { type = "wifi"; }
                    { type = "bluetooth"; }
                    { type = "wallpaper"; }
                    { type = "notification"; }
                    { type = "caffeine"; }
                    { type = "nightlight"; }
                  ];
                };

                dock = {
                  enabled = true;
                  auto_hide = true;
                  reserve_space = false;
                  margin_edge = 8;
                  active_monitor_only = true;
                  show_dots = true;
                  background_opacity = 1.0;
                };

                bar = {
                  main = {
                    position = "top";
                    margin_edge = 4;
                    margin_ends = 4;
                    radius = 4;
                    background_opacity = 0.93;
                    start = [
                      "workspaces"
                      "active_window"
                      "media"
                    ];
                    center = [
                      "clock"
                    ];
                    end = [
                      "tray"
                      "notifications"
                      "clipboard"
                      "battery"
                      "volume"
                      "brightness"
                      "control-center"
                    ];
                  };
                };

                widget = {
                  workspaces = {
                    label_source = "id";
                    max_label_chars = 2;
                    hide_when_empty = true;
                    labels_only_when_occupied = true;
                    focused_color = "secondary";
                    occupied_color = "primary";
                    empty_color = "secondary";
                    font_weight = 700;
                  };

                  active_window = {
                    max_length = 145;
                    title_scroll = "on_hover";
                  };

                  media = {
                    max_length = 145;
                    title_scroll = "on_hover";
                    artist_first = true;
                    hide_when_no_media = true;
                  };

                  clock = {
                    format = "{:%H:%M %a, %b %d}";
                    tooltip_format = "{:%H:%M %a, %b %d}";
                  };

                  tray = {
                    drawer = true;
                    hide_passive = false;
                  };

                  notifications = {
                    hide_when_no_unread = true;
                  };

                  battery = {
                    display_mode = "graphic";
                  };

                  volume = {
                    show_label = false;
                  };

                  brightness = {
                    show_label = false;
                  };

                  "control-center" = {
                    custom_image = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
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
