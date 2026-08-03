{
  lib,
  pkgs,
  inputs,
  symlinkJoin,
  cursorPackage ? pkgs.bibata-cursors,
  cursorTheme ? "Bibata-Modern-Classic",
  cursorSize ? 24,
  licenseSecretPath ? "/run/secrets/yandex-browser",
}:

let
  mkNixPak = inputs.nixpak.lib.nixpak { inherit lib pkgs; };

  # Everything the sandboxed browser needs, merged into one tree: the
  # unwrapped browser itself, plus the managed-policy file it expects to
  # find at a fixed FHS path. yandex-browser-customisation is *not*
  # merged in here -- its var/lib/yandex tree is bind-mounted straight
  # from its own store path below (bind.ro), so nothing needs it
  # duplicated a second time inside this environment too.
  yandex-browser-env = symlinkJoin {
    name = "yandex-browser-corporate-env";
    paths = [ pkgs.yandex-browser-corporate-unwrapped ];
    postBuild = ''
      mkdir -p $out/etc/opt/yandex/browser/policies/managed
      ln -sf ${pkgs.yandex-browser-customisation}/var/lib/yandex/browser-customization/managed/managed_policies.json \
        $out/etc/opt/yandex/browser/policies/managed/managed_policies.json
    '';
  };
in
(mkNixPak {
  config = { sloth, ... }: {
    app.package = yandex-browser-env;
    app.binPath = "bin/yandex-browser-corporate";

    bubblewrap = {
      network = true;
      shareIpc = true;

      bind.dev = [ "/dev" "/dev/snd" ];

      bind.rw = [
        "/run/user/1000"
        "/tmp"
        (sloth.mkdir (sloth.concat' sloth.homeDir "/.yandex/browser"))
        (sloth.mkdir (sloth.concat' sloth.homeDir "/.config/yandex-browser-corporate"))
        (sloth.mkdir (sloth.concat' sloth.homeDir "/.config/yandex-browser"))
        (sloth.mkdir (sloth.concat' sloth.homeDir "/.cache/yandex-browser-corporate"))
        (sloth.mkdir (sloth.concat' sloth.homeDir "/.cache/yandex-browser"))
        (sloth.mkdir (sloth.concat' sloth.homeDir "/.local/share/yandex-browser-corporate"))
        (sloth.mkdir (sloth.concat' sloth.homeDir "/downloads"))
      ];

      bind.ro = [
        # License secret; the browser copies it into its own profile on
        # first run (see the sed block in yandex-browser-corporate.nix).
        licenseSecretPath

        # Corporate managed-policy assets.
        [ "${pkgs.yandex-browser-customisation}/var/lib/yandex" "/var/lib/yandex" ]

        # Audio
        "/run/alsa"
        "/etc/alsa"

        # Base system
        "/etc/static"
        "/etc/group"

        # GPU / graphics
        "/run/opengl-driver"
        "/run/opengl-driver-32"
        "/sys/dev/char"
        "/sys/devices/pci0000:00"
        "/sys/bus/pci"

        # Nix store + current system profile, for shared libraries and
        # binaries referenced by absolute path
        "/nix/store"
        "/run/current-system/sw/bin"

        # Desktop integration
        "/run/dbus/system_bus_socket"

        # Networking / TLS / misc system files
        "/etc/ssl"
        "/etc/static/ssl"
        "/etc/resolv.conf"
        "/etc/hosts"
        "/etc/machine-id"
        "/etc/fonts"
        "/etc/pki"
        "/etc/ssl/certs"
      ];

      extraStorePaths = [ pkgs.coreutils pkgs.bash pkgs.libpulseaudio cursorPackage ];

      env = {
        TZ = "Europe/Minsk";
        PULSE_SERVER = "unix:/run/user/1000/pulse/native";
        XCURSOR_PATH = "${cursorPackage}/share/icons";
        XCURSOR_SIZE = toString cursorSize;
        XCURSOR_THEME = cursorTheme;
        YANDEX_LICENSE_SECRET_PATH = licenseSecretPath;
      };
    };

    dbus = {
      enable = true;
      policies = {
        "org.freedesktop.DBus" = "talk";
        "org.freedesktop.portal.Desktop" = "talk";
        "org.freedesktop.Notifications" = "talk";
        "ca.desrt.dconf" = "talk";
        "org.freedesktop.ScreenSaver" = "talk";
        "org.freedesktop.secrets" = "talk";
        "org.freedesktop.FileManager1" = "talk";
        "org.gnome.SessionManager" = "talk";
        "org.bluez" = "talk";
        "org.freedesktop.UPower" = "talk";
        "org.freedesktop.ReserveDevice1.Audio0" = "talk";
        "org.freedesktop.ReserveDevice1.Audio1" = "talk";
      };
    };
  };
}).config.env
