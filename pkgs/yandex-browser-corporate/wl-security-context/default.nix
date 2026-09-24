{
  lib,
  stdenv,
  pkg-config,
  wayland,
  wayland-scanner,
  wayland-protocols,
}:

# Runs a command on a Wayland socket registered through
# wp_security_context_v1, so the compositor can hide privileged globals from
# it. See the C source for the exact contract.
stdenv.mkDerivation {
  pname = "wl-security-context";
  version = "1";

  src = ./wl-security-context.c;
  dontUnpack = true;

  strictDeps = true;
  nativeBuildInputs = [
    pkg-config
    wayland-scanner
  ];
  buildInputs = [ wayland ];

  buildPhase = ''
    runHook preBuild

    xml=${wayland-protocols}/share/wayland-protocols/staging/security-context/security-context-v1.xml
    wayland-scanner client-header "$xml" security-context-v1-client-protocol.h
    wayland-scanner private-code "$xml" security-context-v1-protocol.c

    $CC -std=c11 -O2 -Wall -Wextra -Werror -I. \
      $(pkg-config --cflags wayland-client) \
      "$src" security-context-v1-protocol.c \
      $(pkg-config --libs wayland-client) \
      -o wl-security-context

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    install -Dm755 wl-security-context "$out/bin/wl-security-context"
    runHook postInstall
  '';

  meta = {
    description = "Run a command on a wp_security_context_v1 restricted Wayland socket";
    platforms = lib.platforms.linux;
    mainProgram = "wl-security-context";
  };
}
