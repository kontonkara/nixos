{ config, lib, pkgs, inputs, username, ... }:

let
  cfg = config.modules.system.services.sunshine;

  # wtype gives its characters codes 1, 2, …, and Chromium treats code 1 as
  # Escape whatever it types, so the first character of every call (and
  # Sunshine calls it per character) was lost or switched the page.
  wtype = pkgs.wtype.overrideAttrs (oldAttrs: {
    patches = (oldAttrs.patches or [ ]) ++ [ ./wtype-printable-keycodes.patch ];
  });
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
        package = pkgs.sunshine.overrideAttrs (oldAttrs: {
          patches = (oldAttrs.patches or [ ]) ++ [
            # Text from Moonlight's soft keyboard (e.g. Cyrillic on a phone)
            # goes through wtype/virtual-keyboard-v1 instead of the
            # Ctrl+Shift+U sequence almost nothing understands.
            ./unicode-via-wtype.patch
            # wlgrab sized its encoder from the last advertised mode, not the
            # current one. niri keeps the 1440x1080 custom mode after the
            # stretched-mode bind, so every stream crashed in ffmpeg's VAAPI
            # encoder on 2560x1440 frames.
            ./current-output-mode.patch
          ];
          postPatch = (oldAttrs.postPatch or "") + ''
            substituteInPlace src/platform/linux/input/inputtino_keyboard.cpp \
              --replace-fail '@wtype@' '${lib.getExe wtype}'
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

    # With no capture method set, Sunshine probes the XDG portal at every
    # start even after wlr-screencopy works, which pops up the screen share
    # picker. Only this key is set, so the web UI keeps the rest.
    home-manager = {
      users = {
        ${username} = { config, ... }: {
          home = {
            activation = {
              sunshineCapture = inputs.home-manager.lib.hm.dag.entryAfter [ "writeBoundary" ] ''
                run mkdir -p "${config.xdg.configHome}/sunshine"
                run ${lib.getExe pkgs.crudini} --set "${config.xdg.configHome}/sunshine/sunshine.conf" "" capture wlr
              '';
            };
          };
        };
      };
    };
  };
}
