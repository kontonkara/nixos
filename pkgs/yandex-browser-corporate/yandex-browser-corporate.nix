{
  stdenv,
  lib,
  requireFile,
  autoPatchelfHook,
  dpkg,
  fetchurl,
  squashfsTools,

  alsa-lib,
  at-spi2-atk,
  at-spi2-core,
  atk,
  bzip2,
  cairo,
  cups,
  curl,
  dbus,
  expat,
  flac,
  fontconfig,
  freetype,
  gcc-unwrapped,
  gdk-pixbuf,
  glib,
  gtk3,
  harfbuzz,
  icu,
  libcap,
  libdrm,
  libexif,
  libgbm,
  libGL,
  libkrb5,
  libopus,
  libpng,
  libpulseaudio,
  libva,
  libx11,
  libxcb,
  libxcomposite,
  libxcursor,
  libxdamage,
  libxext,
  libxfixes,
  libxi,
  libxkbcommon,
  libxrandr,
  libxrender,
  libxscrnsaver,
  libxshmfence,
  libxtst,
  libsForQt5,
  nspr,
  nss,
  pango,
  pciutils,
  pipewire,
  qt6,
  snappy,
  systemd,
  util-linux,
  vulkan-loader,
  wayland,
}:

let
  # Yandex's update helper requests a Chromium-compatible libffmpeg at
  # runtime.  Runtime mutation is disabled, so keep the prebuilt codec used by
  # the previous package until Yandex publishes a redistributable 146 build.
  ffmpeg-codecs = stdenv.mkDerivation {
    pname = "yandex-browser-ffmpeg-codecs";
    version = "N-123075";

    src = fetchurl {
      url = "https://api.snapcraft.io/api/v1/snaps/download/XXzVIXswXKHqlUATPqGCj2w2l7BxosS8_100.snap";
      hash = "sha256-Zd2/gm/v4DvfqOSugoXi4abog+cTDnSXIYnR567LhaQ=";
    };

    nativeBuildInputs = [ squashfsTools ];
    unpackPhase = ''
      runHook preUnpack
      unsquashfs -d . "$src" chromium-ffmpeg-123075/chromium-ffmpeg/libffmpeg.so
      runHook postUnpack
    '';
    installPhase = ''
      runHook preInstall
      install -Dm644 chromium-ffmpeg-123075/chromium-ffmpeg/libffmpeg.so \
        "$out/lib/libffmpeg.so"
      runHook postInstall
    '';
  };

  runtimeLibraries = [
    alsa-lib
    at-spi2-atk
    at-spi2-core
    atk
    bzip2
    cairo
    cups
    curl
    dbus
    expat
    flac
    fontconfig
    freetype
    gcc-unwrapped.lib
    gdk-pixbuf
    glib
    gtk3
    harfbuzz
    icu
    libcap
    libdrm
    libexif
    libgbm
    libGL
    libkrb5
    libopus
    libpng
    libpulseaudio
    libva
    libx11
    libxcb
    libxcomposite
    libxcursor
    libxdamage
    libxext
    libxfixes
    libxi
    libxkbcommon
    libxrandr
    libxrender
    libxscrnsaver
    libxshmfence
    libxtst
    libsForQt5.libqtpas
    nspr
    nss
    pango
    pipewire
    qt6.qtbase
    qt6.qtwayland
    snappy
    systemd
    util-linux
    vulkan-loader
    wayland
  ];

  # autoPatchelf records ELF dependencies automatically.  Keep only libraries
  # loaded dynamically by Chromium/Yandex in every process RUNPATH; adding the
  # complete buildInputs set here needlessly retains their entire closures.
  dlopenLibraries = [
    curl
    gdk-pixbuf
    gtk3
    libGL
    libpulseaudio
    libva
    pciutils
    pipewire
    vulkan-loader
  ];
in
stdenv.mkDerivation (finalAttrs: {
  pname = "yandex-browser-corporate-unwrapped";
  version = "26.4.4.966-1";

  src = requireFile {
    name = "YandexBrowser.deb";
    hash = "sha256-PrzK2kx3KGhIr5kRnXqwy36hb5gDfKYLjKh+oZas+qY=";
    url = "https://browser.yandex.ru";
  };

  nativeBuildInputs = [
    autoPatchelfHook
    dpkg
  ];
  buildInputs = runtimeLibraries;
  runtimeDependencies = map lib.getLib dlopenLibraries;

  strictDeps = false;
  dontConfigure = true;
  dontBuild = true;
  dontStrip = true;
  dontWrapQtApps = true;

  installPhase = ''
    runHook preInstall

    mkdir -p "$out"
    cp -a opt "$out/"
    cp -a usr/share "$out/"

    # Use NixOS's loader so Vulkan ICD discovery follows the driver mounted by
    # nixpak rather than the Ubuntu-specific bundled loader.
    rm -f "$out/opt/yandex/browser/libvulkan.so.1"
    ln -s ${lib.getLib vulkan-loader}/lib/libvulkan.so.1 \
      "$out/opt/yandex/browser/libvulkan.so.1"

    patchelf --add-needed libGL.so.1 "$out/opt/yandex/browser/libGLESv2.so"
    ln -s ${ffmpeg-codecs}/lib/libffmpeg.so \
      "$out/opt/yandex/browser/libffmpeg.so"

    runHook postInstall
  '';

  passthru = {
    inherit (finalAttrs) version;
    browserDir = "opt/yandex/browser";
  };

  meta = {
    description = "Yandex Browser corporate vendor payload";
    homepage = "https://browser.yandex.ru/";
    license = lib.licenses.unfree;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    platforms = [ "x86_64-linux" ];
  };
})
