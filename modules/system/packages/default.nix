{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.modules.packages;
  mcontrolcenterWithExternalProfileSync = pkgs.mcontrolcenter.overrideAttrs (oldAttrs: {
    patches = (oldAttrs.patches or [ ]) ++ [ ./mcontrolcenter-sync-external-profile.patch ];
  });
in
{
  options = {
    modules = {
      packages = {
        enable = lib.mkEnableOption "system utility packages";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    environment = {
      systemPackages = with pkgs; [
        mcontrolcenterWithExternalProfileSync
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
