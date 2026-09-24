{ config, lib, username, ... }:

let
  cfg = config.modules.home.mangohud;
in
{
  options = {
    modules = {
      home = {
        mangohud = {
          enable = lib.mkEnableOption "mangohud overlay config";
        };
      };
    };
  };

  # Per game only (`mangohud %command%`), never session-wide: MangoHud
  # initialises NVML, which would pull the RTX out of D3cold for every app.
  config = lib.mkIf cfg.enable {
    home-manager = {
      users = {
        ${username} = {
          programs = {
            mangohud = {
              enable = true;

              settings = {
                preset = 3;
                horizontal = true;
                legacy_layout = false;
                hud_no_margin = true;
                table_columns = 14;

                # Only the RTX; games run there via nvidia-offload.
                pci_dev = "0000:01:00.0";

                cpu_stats = true;
                cpu_load_change = true;
                cpu_mhz = true;
                cpu_temp = true;
                gpu_stats = true;
                # The stats always come from pci_dev; the name is the device
                # the game renders on, so a missing nvidia-offload shows up.
                gpu_name = true;
                gpu_load_change = true;
                gpu_core_clock = true;
                gpu_mem_clock = true;
                gpu_power = true;
                gpu_power_limit = true;
                gpu_temp = true;
                throttling_status = true;
                ram = true;
                vram = true;
                engine_version = true;
                wine = true;
                # Shows which sync Proton uses — a quick NTsync check.
                winesync = true;
                # Whether gamemoderun took effect.
                gamemode = true;
                fps = true;
                frametime = true;
                frame_timing = true;
              };
            };
          };
        };
      };
    };
  };
}
