{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.modules.packages;
in
{
  options.modules.packages.enable = lib.mkEnableOption "system utility packages";

  config = lib.mkIf cfg.enable {
    environment = {
      systemPackages = with pkgs; [
        mcontrolcenter
        binutils
        pciutils
        usbutils
        nvme-cli
        ryzenadj
        wget
        sops
        age
      ];
    };
  };
}
