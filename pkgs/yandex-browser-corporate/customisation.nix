{
  stdenvNoCC,
  lib,
  requireFile,
  dpkg,
}:

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "yandex-browser-customisation";
  version = "0.2607.2810.4042";

  src = requireFile {
    name = "yandex-browser-customisation.deb";
    hash = "sha256-ZTJrTe5X5RQFynt4HQSLgRzxRVyll05JUnDSrd2KEeg=";
    url = "https://browser.yandex.ru";
  };

  nativeBuildInputs = [ dpkg ];
  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    source_dir=var/lib/yandex/browser-customization
    mkdir -p "$out/customization" "$out/managed"

    for file in partner_config master_preferences distrib_info clids.xml; do
      if [[ -f "$source_dir/$file" ]]; then
        install -Dm644 "$source_dir/$file" "$out/customization/$file"
      fi
    done

    for directory in resources Extensions; do
      if [[ -d "$source_dir/$directory" ]]; then
        cp -a "$source_dir/$directory" "$out/customization/"
      fi
    done

    install -Dm644 "$source_dir/managed/managed_policies.json" \
      "$out/managed/managed_policies.json"

    runHook postInstall
  '';

  passthru = {
    managedPoliciesSubpath = "managed/managed_policies.json";
    customizationSubpath = "customization";
  };

  meta = {
    description = "Corporate customisation payload for Yandex Browser";
    homepage = "https://browser.yandex.ru/";
    license = lib.licenses.unfree;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    platforms = [ "x86_64-linux" ];
  };
})
