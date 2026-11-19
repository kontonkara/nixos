{
  lib,
  stdenv,
  fetchFromGitHub,
  kernel,
  kernelModuleMakeFlags,
}:

# Upstream msi-ec: the in-tree driver and nixpkgs' linuxPackages.msi-ec both
# reject EC firmware 17KKIMS1.115 (Alpha 17 C7VG). Installed under updates/,
# so depmod prefers it over the in-tree msi-ec.
stdenv.mkDerivation {
  pname = "msi-ec";
  version = "0-unstable-2026-11-18";

  src = fetchFromGitHub {
    owner = "BeardOverflow";
    repo = "msi-ec";
    rev = "b1bf9e3f9d0465934ffcfc4f02729725b0ee1973";
    hash = "sha256-W9QpyPRMslstbKjLjtIfPfSCRj/hv7FcHQjjZ4z0RYo=";
  };

  nativeBuildInputs = kernel.moduleBuildDependencies;

  enableParallelBuilding = true;

  # Call kbuild directly: the upstream Makefile hardcodes
  # /lib/modules/$(uname -r)/build.
  preBuild = ''
    makeFlagsArray+=("M=$PWD")
  '';

  makeFlags = kernelModuleMakeFlags ++ [
    "-C"
    "${kernel.dev}/lib/modules/${kernel.modDirVersion}/build"
    "INSTALL_MOD_PATH=${placeholder "out"}"
    "INSTALL_MOD_DIR=updates"
  ];

  buildFlags = [ "modules" ];

  # kbuild's modules_install signs the module like the kernel's own (the
  # .ko.cer that aggregateModules merges since nixpkgs 6bd7526) and
  # compresses it the same way.
  installTargets = [ "modules_install" ];

  meta = {
    description = "Embedded controller driver for MSI laptops (upstream snapshot)";
    homepage = "https://github.com/BeardOverflow/msi-ec";
    license = lib.licenses.gpl2Plus;
    platforms = [
      "x86_64-linux"
    ];
  };
}
