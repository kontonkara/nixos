{
  stdenv,
  lib,
  requireFile,
  dpkg,
}:

# Just the "corporate" customisation payload from Yandex: managed browser
# policies (consumed via var/lib/yandex/browser-customization/managed/...
# in package.nix). No binaries here, nothing to patch.
stdenv.mkDerivation rec {
  pname = "yandex-browser-customisation";
  version = "0.2607.2810.4042";

  src = requireFile {
    name = "yandex-browser-customisation.deb";
    hash = "sha256-ZTJrTe5X5RQFynt4HQSLgRzxRVyll05JUnDSrd2KEeg=";
    url = "https://browser.yandex.ru";
  };

  nativeBuildInputs = [
    dpkg
  ];

  installPhase = ''
    mkdir $out
    cp -r var $out
  '';

  meta = with lib; {
    description = "Yandex Web Browser Customisation";
    homepage = "https://browser.yandex.ru/";
    license = licenses.unfree;
    sourceProvenance = with sourceTypes; [ binaryNativeCode ];
    platforms = [ "x86_64-linux" ];
  };
}
