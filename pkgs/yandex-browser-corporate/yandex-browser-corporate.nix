{
  stdenv,
  lib,
  requireFile,
  autoPatchelfHook,
  wrapGAppsHook3,
  dpkg,
  alsa-lib,
  libgbm,
  nss,
  gtk3,
  libsForQt5,
  qt6,
  curl,
  libGL,
  kdePackages,
  fetchurl,
  squashfsTools,
}:

let
  # Chromium (and so Yandex Browser) can't ship H.264/AAC decoding itself
  # for licensing reasons; upstream expects the browser to fetch a
  # proprietary-codec ffmpeg build at runtime. That can't happen from a
  # sandboxed, offline Nix build, so we lift the same library Ubuntu's
  # Chromium snap ships and link it in ourselves instead (see the
  # libffmpeg.so symlink and the neutered update_codecs/find_ffmpeg
  # scripts below).
  ffmpeg-codecs = stdenv.mkDerivation {
    pname = "yandex-browser-ffmpeg-codecs";
    version = "snap-chromium";
    src = fetchurl {
      url = "https://api.snapcraft.io/api/v1/snaps/download/XXzVIXswXKHqlUATPqGCj2w2l7BxosS8_100.snap";
      sha256 = "1945rfpfglc946bp83hkwy1yi9p1wa2q5bp4m3gkpq7gdy1bzpb5";
    };
    nativeBuildInputs = [ squashfsTools ];
    unpackPhase = "unsquashfs -d . $src chromium-ffmpeg-123075/chromium-ffmpeg/libffmpeg.so";
    installPhase = "mkdir -p $out/lib && cp chromium-ffmpeg-123075/chromium-ffmpeg/libffmpeg.so $out/lib/";
  };
in
stdenv.mkDerivation rec {
  pname = "yandex-browser-corporate";
  version = "26.4.4.966-1";

  src = requireFile {
    name = "YandexBrowser.deb";
    hash = "sha256-PrzK2kx3KGhIr5kRnXqwy36hb5gDfKYLjKh+oZas+qY=";
    url = "https://browser.yandex.ru";
  };

  nativeBuildInputs = [
    autoPatchelfHook
    qt6.wrapQtAppsHook
    wrapGAppsHook3
    dpkg
  ];

  dontConfigure = true;
  dontBuild = true;

  buildInputs = [
    alsa-lib
    libgbm
    nss
    gtk3
    libsForQt5.libqtpas
    qt6.qtbase
    curl
    kdePackages.qtwayland
  ];

  installPhase = ''
    mkdir -p $out/bin

    # --- Desktop-entry metadata --------------------------------------
    # Renamed so this can live alongside the regular yandex-browser
    # package without file collisions.
    rm -f usr/share/applications/ru.yandex.desktop.browser.desktop || true
    if [ -f usr/share/applications/yandex-browser.desktop ]; then
      mv usr/share/applications/{yandex-browser.desktop,''${pname}.desktop}
      mv usr/share/appdata/{yandex-browser.appdata.xml,''${pname}.appdata.xml}
      mv usr/share/gnome-control-center/default-apps/{yandex-browser.xml,''${pname}.xml}

      # Human-readable name only: "Yandex Browser" (capitalised, with a
      # space) never collides with the lowercase "yandex-browser"
      # identifier used by Exec=/Icon=/StartupWMClass=, so a blanket
      # replace is safe here.
      substituteInPlace \
          usr/share/applications/''${pname}.desktop \
          usr/share/gnome-control-center/default-apps/''${pname}.xml \
          usr/share/appdata/''${pname}.appdata.xml \
          --replace-fail "Yandex Browser" "Yandex Browser Corporate"

      # appdata's <id> and the GNOME "default apps" entry both reference
      # the desktop file by its (renamed) filename, so the bare
      # identifier does need to change in these two files.
      # --replace-warn keeps this tolerant of whichever form a given
      # vendor build happens to ship.
      substituteInPlace \
          usr/share/gnome-control-center/default-apps/''${pname}.xml \
          usr/share/appdata/''${pname}.appdata.xml \
          --replace-warn "yandex-browser-corporate" "yandex-browser" \
          --replace-fail "yandex-browser" "''${pname}"

      # The .desktop file gets a lighter touch. Icon= and
      # StartupWMClass= must stay exactly "yandex-browser": the icon
      # files copied in below are never renamed, and the running
      # browser process still reports WM_CLASS=yandex-browser no matter
      # what we call the launcher. Renaming those two keys is what used
      # to leave the app with a generic icon in the menu and taskbar.
      # Only Exec=/TryExec= need to change, and to a bare command name
      # rather than an absolute path, so it resolves via $PATH to
      # whatever ends up actually installed under that name (see
      # package.nix for why that's the sandboxed build, not this one).
      sed -E -i \
          -e "s|^Exec=\S+|Exec=''${pname}|" \
          -e "s|^TryExec=.*|TryExec=''${pname}|" \
          usr/share/applications/''${pname}.desktop
    fi

    cp -r {usr/share,opt} $out/

    ln -sf $out/opt/yandex/browser/yandex-browser $out/bin/''${pname}

    if [ -f $out/share/applications/''${pname}.desktop ]; then
      # Catch-all for any remaining absolute /usr/ paths (e.g. an
      # absolute Icon=). Exec=/TryExec= are already bare command names
      # by this point, so this can no longer smuggle an absolute,
      # unwrapped path back into Exec=.
      substituteInPlace $out/share/applications/''${pname}.desktop --replace-warn /usr/ $out/

      substituteInPlace $out/share/gnome-control-center/default-apps/''${pname}.xml \
          --replace-fail /opt/yandex/browser/''${pname} $out/bin/''${pname}
    fi

    # --- GPU / video ---------------------------------------------------
    patchelf --add-needed libGL.so.1 $out/opt/yandex/browser/libGLESv2.so
    ln -sf ${ffmpeg-codecs}/lib/libffmpeg.so $out/opt/yandex/browser/libffmpeg.so

    # The vendor's own codec-fetching machinery would try to hit the
    # network at runtime and can't do anything useful inside the
    # sandbox anyway, now that libffmpeg.so is linked in above.
    for s in update_codecs find_ffmpeg; do
      rm -f $out/opt/yandex/browser/$s
      echo -e "#!/bin/sh\nexit 0" > $out/opt/yandex/browser/$s
      chmod +x $out/opt/yandex/browser/$s
    done

    # --- License handling -- left exactly as-is on purpose. Reads
    # $YANDEX_LICENSE_SECRET_PATH (set in package.nix) and copies it
    # into the browser's own profile on first run if nothing is there
    # yet. ------------------------------------------------------------
    sed -i '/exec -a/i \
if [ -n "$YANDEX_LICENSE_SECRET_PATH" ] && [ -f "$YANDEX_LICENSE_SECRET_PATH" ]; then\n\
  mkdir -p ~/.yandex/browser\n\
  if [ ! -f ~/.yandex/browser/license ] || ! grep -q "[^[:space:]]" ~/.yandex/browser/license; then\n\
    cp -f "$YANDEX_LICENSE_SECRET_PATH" ~/.yandex/browser/license 2>/dev/null || true\n\
    chmod 600 ~/.yandex/browser/license 2>/dev/null || true\n\
  fi\n\
fi\n' $out/opt/yandex/browser/yandex-browser
  '';

  runtimeDependencies = map lib.getLib (
    [
      libGL
    ]
    ++ buildInputs
  );

  meta = with lib; {
    description = "Yandex Web Browser";
    homepage = "https://browser.yandex.ru/";
    license = licenses.unfree;
    sourceProvenance = with sourceTypes; [ binaryNativeCode ];
    mainProgram = "yandex-browser-corporate";
    platforms = [ "x86_64-linux" ];
  };
}
