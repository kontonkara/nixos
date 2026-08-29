{ config, lib, ... }:

let
  cfg = config.modules.services.udev;
in
{
  options.modules.services.udev.enable =
    lib.mkEnableOption "desktop access to Compx MAD mouse HID interfaces";

  config = lib.mkIf cfg.enable {
    services.udev.extraRules = ''
      # Compx MAD 8K dongle
      SUBSYSTEM=="hidraw", KERNEL=="hidraw*", ATTRS{idVendor}=="373b", ATTRS{idProduct}=="1040", MODE="0660", TAG+="uaccess"

      # Compx MAD R MAJOR+ normal mode
      SUBSYSTEM=="hidraw", KERNEL=="hidraw*", ATTRS{idVendor}=="373b", ATTRS{idProduct}=="104c", MODE="0660", TAG+="uaccess"

      # Compx MAD R MAJOR+ firmware-update mode
      SUBSYSTEM=="hidraw", KERNEL=="hidraw*", ATTRS{idVendor}=="3554", ATTRS{idProduct}=="f408", MODE="0660", TAG+="uaccess"
    '';
  };
}
