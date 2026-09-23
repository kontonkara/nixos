{ config, lib, ... }:

let
  cfg = config.modules.system.services.sunshine;
in
{
  options = {
    modules = {
      system = {
        services = {
          sunshine = {
            enable = lib.mkEnableOption "sunshine game stream host";
          };
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    services = {
      sunshine = {
        enable = true;
        # Moonlight talks to a range of ports around 47989.
        openFirewall = true;
        # DRM/KMS capture, required on Wayland (niri).
        capSysAdmin = true;
        # settings left empty on purpose so the web UI at
        # https://localhost:47989 can manage config and applications.
      };
    };
  };
}
