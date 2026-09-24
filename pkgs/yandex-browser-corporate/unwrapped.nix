{
  stdenv,
  lib,
  requireFile,
  autoPatchelfHook,
  dpkg,

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
  # Qt5 shim is unused (--qt-version=6); Qt5+Qt6 cannot share one derivation.
  autoPatchelfIgnoreMissingDeps = [
    "libQt5Core.so.5"
    "libQt5Gui.so.5"
    "libQt5Widgets.so.5"
  ];

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

    # ANGLE/Vulkan are dlopen'd: same RPATH recipe as nixpkgs chromium.
    for elf in "$out/opt/yandex/browser/yandex_browser" \
               "$out/opt/yandex/browser/libGLESv2.so"; do
      patchelf --set-rpath "${
        lib.makeLibraryPath [
          libGL
          vulkan-loader
          pciutils
        ]
      }:$(patchelf --print-rpath "$elf")" "$elf"
    done

    rm -f "$out/opt/yandex/browser/libvulkan.so.1"
    ln -s ${lib.getLib vulkan-loader}/lib/libvulkan.so.1 \
      "$out/opt/yandex/browser/libvulkan.so.1"

    patchelf --add-needed libGL.so.1 "$out/opt/yandex/browser/libGLESv2.so"

    # setuid helper is unused inside NixPak's user namespace
    chmod u-s "$out/opt/yandex/browser/yandex_browser-sandbox"

    # clids.xml is plain XML with junk before the declaration. Every other
    # partner file here is signed and must stay byte-for-byte.
    clids=$out/opt/yandex/browser/clids.xml
    if [[ -f $clids ]]; then
      sed -i -e '/<?xml/,$!d' -e 's/^[[:space:]]*//' "$clids"
    fi

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
