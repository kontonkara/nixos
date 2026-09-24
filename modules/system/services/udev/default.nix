{ config, lib, pkgs, ... }:

let
  cfg = config.modules.system.services.udev;

  # uaccess only takes effect from a rules file numbered below 73
  # (73-seat-late.rules acts on it; systemd >= 258 ignores later tags), so
  # these can't go into services.udev.extraRules (99-local.rules).
  peripheralRules = pkgs.writeTextFile {
    name = "peripheral-udev-rules";
    destination = "/etc/udev/rules.d/70-peripherals.rules";
    text = ''
      # Compx MAD 8K dongle
      SUBSYSTEM=="hidraw", KERNEL=="hidraw*", ATTRS{idVendor}=="373b", ATTRS{idProduct}=="1040", MODE="0660", TAG+="uaccess"

      # Compx MAD R MAJOR+ normal mode
      SUBSYSTEM=="hidraw", KERNEL=="hidraw*", ATTRS{idVendor}=="373b", ATTRS{idProduct}=="104c", MODE="0660", TAG+="uaccess"

      # Compx MAD R MAJOR+ firmware-update mode
      SUBSYSTEM=="hidraw", KERNEL=="hidraw*", ATTRS{idVendor}=="3554", ATTRS{idProduct}=="f408", MODE="0660", TAG+="uaccess"
    '';
  };
in
{
  options = {
    modules = {
      system = {
        services = {
          udev = {
            enable = lib.mkEnableOption "udev access rules for peripherals (web configurators)";
          };
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    services = {
      udev = {
        packages = [ peripheralRules ];
      };
    };
  };
}
