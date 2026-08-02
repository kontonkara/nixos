{ ... }:

{
  environment = {
    sessionVariables = {
      NIXOS_OZONE_WL = "1";
      ELECTRON_OZONE_PLATFORM_HINT = "auto";
      MOZ_ENABLE_WAYLAND = "1";
      MESA_SHADER_CACHE_MAX_SIZE = "1G";
      MESA_DISK_CACHE_SINGLE_FILE = "1";
    };
  };
}
