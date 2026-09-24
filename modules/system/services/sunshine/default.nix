{ config, lib, pkgs, ... }:

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
        # Text from Moonlight's soft keyboard (e.g. Cyrillic on a phone) goes
        # through wtype/virtual-keyboard-v1 instead of the Ctrl+Shift+U
        # sequence almost nothing understands.
        package = pkgs.sunshine.overrideAttrs (oldAttrs: {
          patches = (oldAttrs.patches or [ ]) ++ [ ./unicode-via-wtype.patch ];
          postPatch = (oldAttrs.postPatch or "") + ''
            substituteInPlace src/platform/linux/input/inputtino_keyboard.cpp \
              --replace-fail '@wtype@' '${lib.getExe pkgs.wtype}'
          '';
        });
        # Moonlight talks to a range of ports around 47989.
        openFirewall = true;
        # No capSysAdmin: on niri Sunshine picks wlr-screencopy (wlgrab) and
        # drops the capability anyway; it's only needed for capture=kms.
        # settings left empty on purpose so the web UI at
        # https://localhost:47989 can manage config and applications.
      };
    };
  };
}
