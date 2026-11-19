{
  lib,
  stdenvNoCC,
  fetchurl,
  autoPatchelfHook,
  addDriverRunpath,
  makeWrapper,
  stdenv,
  zlib,
  libxcrypt-legacy,
}:

let
  release = "0.2.16";
  component = "0.1.62";
  base = "https://github.com/Niko1221/Strata/releases/download/v${release}";
in
stdenvNoCC.mkDerivation {
  pname = "strata";
  version = release;

  # The release's own archives, as its installer fetches them: the terminal
  # (the CLI, the OpenAI/Anthropic server and a relocatable CPython with its
  # locked wheels) and the CUDA 13 engine.
  srcs = [
    (fetchurl {
      url = "${base}/strata-control-${component}-linux-x86_64.tar.gz";
      hash = "sha256-BFtqfX+/vdq4FHlNtXY9YkTIh6OUQDuf4OikcU2b74w=";
    })
    (fetchurl {
      url = "${base}/strata-engine-${component}-linux-x86_64-cuda-cuda13.tar.gz";
      hash = "sha256-ZyPhtrYEK/4dNocj6/hzr7D6ZfTxkI2UjdhlCY9s+54=";
    })
  ];

  # Both unpack into the current directory.
  unpackPhase = ''
    runHook preUnpack
    srcs=($srcs)
    mkdir terminal engine
    tar -xzf "''${srcs[0]}" -C terminal
    tar -xzf "''${srcs[1]}" -C engine
    runHook postUnpack
  '';

  nativeBuildInputs = [
    autoPatchelfHook
    addDriverRunpath
    makeWrapper
  ];

  buildInputs = [
    stdenv.cc.cc.lib
    zlib
    # _crypt in the bundled CPython.
    libxcrypt-legacy
  ];

  # The driver's libraries are only there at run time.
  autoPatchelfIgnoreMissingDeps = [
    "libcuda.so.1"
    "libnvidia-ml.so.1"
  ];

  dontConfigure = true;
  dontBuild = true;
  dontStrip = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/share/strata $out/bin
    cp -r terminal $out/share/strata/terminal
    cp -r engine $out/share/strata/engine
    makeWrapper $out/share/strata/terminal/python/bin/python3.12 $out/bin/strata-python \
      --set PYTHONDONTWRITEBYTECODE 1 \
      --chdir $out/share/strata/terminal
    makeWrapper $out/share/strata/terminal/bin/strata $out/bin/strata \
      --set STRATA_PYTHON $out/share/strata/terminal/python/bin/python3.12 \
      --set STRATA_UPDATE_CHECK 0 \
      --set PYTHONDONTWRITEBYTECODE 1
    runHook postInstall
  '';

  # The engine and its CUDA runtime dlopen libcuda.so.1 from the driver.
  postFixup = ''
    for elf in $out/share/strata/engine/strata* $out/share/strata/engine/*.so*; do
      isELF "$elf" && addDriverRunpath "$elf"
    done
  '';

  passthru = {
    engine = "share/strata/engine/strata";
    terminal = "share/strata/terminal";
  };

  meta = {
    description = "Runs large MoE models from SSD and RAM on a small GPU";
    homepage = "https://github.com/Niko1221/Strata";
    license = lib.licenses.mit;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    platforms = [ "x86_64-linux" ];
    mainProgram = "strata";
  };
}
