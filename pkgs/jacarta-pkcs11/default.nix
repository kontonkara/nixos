{
  stdenv,
  lib,
  fetchurl,
  dpkg,
  pcsclite,
}:

# Aladdin's PKCS#11 library for JaCarta tokens. OpenSC doesn't know the
# JaCarta PKI applet ("Unsupported card"), so this is the only way in. Taken
# from the Debian build of the JaCarta Unified Client, of which only the
# jcpkcs11-2 package is needed: the rest is a Qt GUI for PINs and
# certificates. Its postinst only edits the CCID driver's Info.plist for
# readers that nixpkgs' ccid already lists (24dc:0101 included).
#
# The libraries are signed (a "signature" section, checked by Aladdin's
# jcverify) and lack the .gnu.version section patchelf needs, so they are
# installed untouched. Instead libpcsclite.so.1 sits next to them: whatever
# loads libjcPKCS11-2.so puts this lib/ on LD_LIBRARY_PATH, which also
# finds the siblings it dlopens by bare name (libjckt2.so and others).
stdenv.mkDerivation (finalAttrs: {
  pname = "jacarta-pkcs11";
  version = "2.11.3.1094";

  src = fetchurl {
    url = "https://www.aladdin-rd.ru/upload/downloads/JaCarta_UC/jacarta-3.3/lunix/distributions/jacartauc_3.3.5.3866_deb_x64.tgz";
    hash = "sha256-26Ji9l3lLG1uG4hmaVaYnsUYcAAusg1vGv/wl59iarE=";
  };

  nativeBuildInputs = [ dpkg ];

  dontPatchELF = true;
  dontStrip = true;

  unpackPhase = ''
    runHook preUnpack
    tar -xzf $src jcpkcs11-2_${finalAttrs.version}_x64.deb
    dpkg-deb -x jcpkcs11-2_${finalAttrs.version}_x64.deb .
    runHook postUnpack
  '';

  installPhase = ''
    runHook preInstall
    install -Dm755 usr/lib/libjcPKCS11-2.so.2.11.3 $out/lib/libjcPKCS11-2.so
    install -Dm755 -t $out/lib usr/lib/libASEP11.so usr/lib/libjcPKCS11ds.so usr/lib/libjckt2.so
    ln -s ${lib.getLib pcsclite}/lib/libpcsclite.so.1 $out/lib/libpcsclite.so.1
    runHook postInstall
  '';

  meta = {
    description = "PKCS#11 library for Aladdin JaCarta tokens";
    homepage = "https://www.aladdin-rd.ru/support/downloads/jacarta_client";
    license = lib.licenses.unfree;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    platforms = [ "x86_64-linux" ];
  };
})
