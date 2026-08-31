{
  config,
  lib,
  username,
  ...
}:

let
  cfg = config.modules.home.htop;
in
{
  options.modules.home.htop.enable = lib.mkEnableOption "htop";

  config = lib.mkIf cfg.enable {
    home-manager.users.${username}.programs.htop = {
      enable = true;

      settings = {
        config_reader_min_version = 3;
        detailed_cpu_time = true;
        header_margin = true;
        hide_kernel_threads = true;
        hide_userland_threads = true;
        highlight_base_name = true;
        show_cpu_frequency = true;
        show_cpu_temperature = true;
        show_cpu_usage = true;
        show_program_path = false;
        tree_view = true;

        header_layout = "two_50_50";

        column_meters_0 = [
          "LeftCPUs2"
          "Memory"
          "Zram"
        ];

        column_meter_modes_0 = [
          1
          1
          1
        ];

        column_meters_1 = [
          "RightCPUs2"
          "Tasks"
          "LoadAverage"
          "Uptime"
          "DiskIO"
          "Battery"
        ];

        column_meter_modes_1 = [
          1
          2
          2
          2
          2
          2
        ];
      };
    };
  };
}
