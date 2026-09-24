{
  lib,
  stdenv,
  fetchFromGitHub,
  kernel,
  kernelModuleMakeFlags,
  xz,
}:

# Upstream msi-ec: the in-tree driver and nixpkgs' linuxPackages.msi-ec both
# reject EC firmware 17KKIMS1.115 (Alpha 17 C7VG). Installed under updates/,
# so depmod prefers it over the in-tree msi-ec.
stdenv.mkDerivation {
  pname = "msi-ec";
  version = "0-unstable-2026-08-10";

  src = fetchFromGitHub {
    owner = "BeardOverflow";
    repo = "msi-ec";
    rev = "d7fbbd88e6831e56801b860e46475cbf8ddbc7c1";
    hash = "sha256-+XNrhKeltD5eaasqDOdQ/9/dcPf1H6z2N8hGB344POQ=";
  };

  nativeBuildInputs = kernel.moduleBuildDependencies ++ [
    xz
  ];

  enableParallelBuilding = true;

  # Call kbuild directly: the upstream Makefile hardcodes
  # /lib/modules/$(uname -r)/build.
  preBuild = ''
    makeFlagsArray+=("M=$PWD")
  '';

  makeFlags = kernelModuleMakeFlags ++ [
    "-C"
    "${kernel.dev}/lib/modules/${kernel.modDirVersion}/build"
    "modules"
  ];

  installPhase = ''
    runHook preInstall

    destDir="$out/lib/modules/${kernel.modDirVersion}/updates"
    install -Dm444 msi-ec.ko -t "$destDir"
    xz -f "$destDir/msi-ec.ko"

    runHook postInstall
  '';

  meta = {
    description = "Embedded controller driver for MSI laptops (upstream snapshot)";
    homepage = "https://github.com/BeardOverflow/msi-ec";
    license = lib.licenses.gpl2Plus;
    platforms = [
      "x86_64-linux"
    ];
  };
}
