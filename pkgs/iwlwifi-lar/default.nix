{
  stdenv,
  kernel,
  kernelModuleMakeFlags,
  xz,
}:

# Out-of-tree rebuild of the whole iwlwifi tree (iwlwifi + dvm/mvm/mld) with
# the lar_disable modparam restored. Installed under updates/, so depmod
# prefers it over the in-tree modules.
stdenv.mkDerivation {
  pname = "iwlwifi-lar";
  inherit (kernel) version src;

  patches = [
    ./lar_disable.patch
  ];

  nativeBuildInputs = kernel.moduleBuildDependencies ++ [
    xz
  ];

  enableParallelBuilding = true;

  preBuild = ''
    cd drivers/net/wireless/intel/iwlwifi
    makeFlagsArray+=("M=$PWD")
  '';

  makeFlags = kernelModuleMakeFlags ++ [
    "-C"
    "${kernel.dev}/lib/modules/${kernel.modDirVersion}/build"
    "modules"
  ];

  installPhase = ''
    runHook preInstall

    destDir="$out/lib/modules/${kernel.modDirVersion}/updates/iwlwifi"
    mkdir -p "$destDir"
    find . -name '*.ko' -exec cp --parents '{}' "$destDir" \;
    find "$destDir" -name '*.ko' -exec xz -f '{}' \;

    runHook postInstall
  '';

  meta = {
    description = "iwlwifi rebuilt with the lar_disable modparam";
    inherit (kernel.meta) license;
    platforms = [
      "x86_64-linux"
    ];
  };
}
