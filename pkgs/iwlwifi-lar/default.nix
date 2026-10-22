{
  stdenv,
  kernel,
  kernelModuleMakeFlags,
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

  nativeBuildInputs = kernel.moduleBuildDependencies;

  enableParallelBuilding = true;

  preBuild = ''
    cd drivers/net/wireless/intel/iwlwifi
    makeFlagsArray+=("M=$PWD")
  '';

  makeFlags = kernelModuleMakeFlags ++ [
    "-C"
    "${kernel.dev}/lib/modules/${kernel.modDirVersion}/build"
    "INSTALL_MOD_PATH=${placeholder "out"}"
    "INSTALL_MOD_DIR=updates/iwlwifi"
  ];

  buildFlags = [ "modules" ];

  # kbuild's modules_install signs the modules like the kernel's own (the
  # .ko.cer that aggregateModules merges since nixpkgs 6bd7526) and
  # compresses them the same way.
  installTargets = [ "modules_install" ];

  meta = {
    description = "iwlwifi rebuilt with the lar_disable modparam";
    inherit (kernel.meta) license;
    platforms = [
      "x86_64-linux"
    ];
  };
}
