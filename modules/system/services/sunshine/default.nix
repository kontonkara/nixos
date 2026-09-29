{ config, lib, pkgs, ... }:

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
          ];
          postPatch = (oldAttrs.postPatch or "") + ''
            substituteInPlace src/platform/virtualhid_input.cpp \
              --replace-fail '@wtype@' '${lib.getExe wtype}'
          '';
        });
        # No openFirewall: it also opens the web UI (base + 1) to every
        # network; the ports Moonlight needs are opened below.
        # No capSysAdmin: on niri Sunshine picks wlr-screencopy (wlgrab) and
        # drops the capability anyway; it's only needed for capture=kms.

        # With these set the module passes its own sunshine.conf, so the web
        # UI (https://localhost:47990) can no longer save settings or apps.
        # Pairing and certificates stay in ~/.config/sunshine.
        settings = {
          # Without it Sunshine probes the XDG portal at every start, even
          # after wlr-screencopy works, and pops up the screen share picker.
          capture = "wlr";
          # Sound keeps playing on the laptop, not on the phone.
          stream_audio = "disabled";
        };

        applications = {
          env = {
            PATH = "$(PATH):$(HOME)/.local/bin";
          };
          apps = [
            {
              name = "Desktop";
              image-path = "desktop.png";
            }
            {
              name = "Steam Big Picture";
              image-path = "steam.png";
              detached = [ "setsid steam steam://open/bigpicture" ];
              prep-cmd = [
                {
                  do = "";
                  undo = "setsid steam steam://close/bigpicture";
                }
              ];
            }
          ];
        };
      };
    };

    # openFirewall's offsets from the base port (47989) minus +1, the web UI:
    # HTTPS, HTTP and RTSP over TCP; video, control, audio and mic over UDP.
    networking = {
      firewall =
        let
          ports = map (offset: config.services.sunshine.settings.port + offset);
        in
        {
          allowedTCPPorts = ports [ (-5) 0 21 ];
          allowedUDPPorts = ports [ 9 10 11 13 21 ];
        };
    };
  };
}
