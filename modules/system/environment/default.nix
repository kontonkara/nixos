{ config, lib, ... }:

let
  cfg = config.modules.system.environment;
in
{
  options = {
    modules = {
      system = {
        environment = {
          enable = lib.mkEnableOption "wayland desktop environment variables";

          gaming = {
            enable = lib.mkEnableOption "proton and steam environment variables";
          };
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    environment = {
      sessionVariables = {
        # Do NOT set GDK_BACKEND globally — niri wiki: it breaks the
        # screencast portal. GTK defaults to Wayland on its own.
        QT_QPA_PLATFORM = "wayland;xcb";
        QT_QPA_PLATFORMTHEME = "gtk3";
        QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";

        # Belt-and-suspenders: NixOS 25.05+ already prefers Wayland for
        # Chromium/Electron when XDG_SESSION_TYPE=wayland.
        NIXOS_OZONE_WL = "1";
        ELECTRON_OZONE_PLATFORM_HINT = "auto";
        MOZ_ENABLE_WAYLAND = "1";

        # OpenJDK is still X11; this keeps JetBrains/Java tools sane on XWayland.
        _JAVA_AWT_WM_NONREPARENTING = "1";

        # AMD iGPU media + shader cache for the znver4 mesa build.
        LIBVA_DRIVER_NAME = "radeonsi";
        MESA_SHADER_CACHE_MAX_SIZE = "1G";
      }
      // lib.optionalAttrs cfg.gaming.enable {
        # SDL2 / SDL3 (SDL3 prefers Wayland when the compositor has fifo-v1).
        SDL_VIDEODRIVER = "wayland,x11";
        SDL_VIDEO_DRIVER = "wayland,x11";

        PROTON_ENABLE_WAYLAND = "1";
        PROTON_USE_NTSYNC = "1";
        PROTON_USE_WOW64 = "1";
        STEAM_FORCE_DESKTOPUI_SCALING = "1";
      };
    };
  };
}
