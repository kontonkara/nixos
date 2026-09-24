{ config, lib, username, ... }:

let
  cfg = config.modules.home.btop;
in
{
  options = {
    modules = {
      home = {
        btop = {
          enable = lib.mkEnableOption "btop resource monitor";
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    home-manager = {
      users = {
        ${username} = {
          programs = {
            btop = {
              enable = true;

              settings = {
                # The default list includes nvidia: btop would load NVML and
                # pull the RTX out of D3cold for as long as it runs.
                shown_gpus = "amd intel";
              };
            };
          };
        };
      };
    };
  };
}
