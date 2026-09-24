{ config, lib, username, ... }:

let
  cfg = config.modules.system.environment;

  hmStylix = config.home-manager.users.${username}.stylix;
  qtFromStylix = hmStylix.enable && hmStylix.targets.qt.enable;
in
{
  options = {
    modules = {
      system = {
        environment = {
          enable = lib.mkEnableOption "wayland desktop environment variables";

          gaming = {
            enable = lib.mkEnableOption "gaming tweaks (ntsync, nvidia shader cache)";
          };
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    environment = {
      sessionVariables = {
        # Do NOT set GDK_BACKEND globally — niri wiki: it breaks the
        # screencast portal. GTK defaults to Wayland on its own, and so do
        # Qt (wayland;xcb), Firefox and Electron 38+; with prefer-no-csd Qt
        # already gets server-side decorations.

        # Qt only picks the gtk3 theme by itself on GNOME/XFCE/MATE/…,
        # not when XDG_CURRENT_DESKTOP=niri. Stylix's Home Manager qt target
        # sets qt5ct (+ Kvantum) in the user's environment.d instead; two
        # values from different layers would race.
        QT_QPA_PLATFORMTHEME = lib.mkIf (!qtFromStylix) "gtk3";

        # nixpkgs Electron wrappers (obsidian, vesktop, …) read this to add
        # Wayland IME/text-input-v3 and window-decoration flags.
        NIXOS_OZONE_WL = "1";

        # OpenJDK is still X11; this keeps JetBrains/Java tools sane on XWayland.
        _JAVA_AWT_WM_NONREPARENTING = "1";

        # GTK4's default Vulkan renderer enumerates every ICD, which pulls
        # the RTX out of D3cold (~2s per launch) and keeps /dev/nvidia0 open
        # for the window's lifetime. The GL renderer stays on the iGPU.
        # ("ngl" was renamed to "gl" in GTK 4.20 and now warns.)
        GSK_RENDERER = "gl";
      }
      // lib.optionalAttrs cfg.gaming.enable {
        # The NVIDIA driver prunes its shader cache at 1 GiB, wiping Steam's
        # precompiled Fossilize caches; its README says to raise it globally.
        __GL_SHADER_DISK_CACHE_SIZE = "10737418240";

        # Keep SDL_VIDEODRIVER / PROTON_ENABLE_WAYLAND / nvidia-offload in
        # per-game launch options: niri has no fifo-v1, so SDL3 picks XWayland
        # on purpose, and a global SDL override skips sdl2-compat's quirks.
      };
    };

    # Proton 11 and GE-Proton use NTSync on their own once /dev/ntsync
    # exists, but the module has no devname alias and never autoloads.
    boot.kernelModules = lib.mkIf cfg.gaming.enable [ "ntsync" ];
  };
}
