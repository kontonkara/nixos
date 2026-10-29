{
  lib,
  callPackage,
  inputs,
  python312,
  cudaPackages_13,
  ninja,
}:

let
  python = python312;

  # torch 2.14.1 from the lock is the cu130 build; the fork's extensions are
  # compiled against this toolkit.
  cuda = cudaPackages_13.cudatoolkit;

  workspace = inputs.uv2nix.lib.workspace.loadWorkspace { workspaceRoot = ./.; };

  overlay = workspace.mkPyprojectOverlay { sourcePreference = "wheel"; };

  inherit (callPackage inputs.pyproject-nix.build.hacks { }) nixpkgsPrebuilt;

  # The same wheels as in the lock (torch 2.14.1+cu130, triton 3.8.0), already
  # patched against nixpkgs' CUDA. Wheels split across packages defeat
  # autoPatchelf: torchvision's extensions look for libtorch in torch's
  # store path, and the nvidia-* wheels for each other.
  prebuilt = {
    torch = python.pkgs.torch-bin;
    torchvision = python.pkgs.torchvision-bin;
    triton = python.pkgs.triton-bin;
  };

  torchLib = "${prebuilt.torch}/${python.sitePackages}/torch/lib";

  locked = map (package: package.name) (lib.importTOML ./uv.lock).package;

  # Wheels get autoPatchelfHook from pyproject.nix; the driver's libraries
  # are only there at run time (/run/opengl-driver/lib).
  driverOnly = [
    "libcuda.so.1"
    "libnvidia-ml.so.1"
  ];

  patchWheel =
    prev: name:
    prev.${name}.overrideAttrs (
      old:
      # The CUDA library wheels find each other through $ORIGIN, which
      # autoPatchelf would replace (cuDNN then can't open its sub-libraries).
      if lib.hasPrefix "nvidia-" name || lib.hasPrefix "cuda-" name then
        { dontAutoPatchelf = true; }
      else
        {
          # The kernels' extensions link libtorch and the CUDA runtime.
          buildInputs = (old.buildInputs or [ ]) ++ [ cudaPackages_13.cuda_cudart ];
          preFixup = (old.preFixup or "") + ''
            addAutoPatchelfSearchPath ${torchLib}
          '';
          autoPatchelfIgnoreMissingDeps = driverOnly;
        }
    );

  isWheel = package: lib.hasSuffix ".whl" (package.src.name or "");

  overrides =
    final: prev:
    lib.genAttrs (lib.filter (name: prev ? ${name} && !prebuilt ? ${name}) locked) (
      name: if isWheel prev.${name} then patchWheel prev name else prev.${name}
    )
    // lib.mapAttrs (
      name: from:
      nixpkgsPrebuilt {
        inherit from;
        prev = prev.${name};
      }
    ) prebuilt
    // {
      # Its extensions find libtorch and the CUDA runtime already loaded by
      # torch.
      freetoken = prev.freetoken.overrideAttrs (old: {
        # uv doesn't lock build systems: setup.py imports torch's
        # BuildExtension and builds the pinned-memory, ggml-cpu and CUDA
        # extensions with nvcc.
        nativeBuildInputs =
          old.nativeBuildInputs
          ++ final.resolveBuildSystem {
            setuptools = [ ];
            wheel = [ ];
            torch = [ ];
          }
          ++ [
            cuda
            ninja
          ];
        # The nixpkgs builds lack the setup hook that puts uv2nix packages on
        # the build's path.
        preBuild = (old.preBuild or "") + ''
          addToSearchPath NIX_PYPROJECT_PYTHONPATH ${final.torch}/${python.sitePackages}
          addToSearchPath NIX_PYPROJECT_PYTHONPATH ${final.triton}/${python.sitePackages}
        '';
        env = (old.env or { }) // {
          CUDA_HOME = "${cuda}";
          # nvcc.profile in the merged toolkit points at nvcc's own output, so
          # nvcc doesn't add the runtime headers next to it.
          CPATH = "${cuda}/include";
          LIBRARY_PATH = "${cuda}/lib:${cuda}/lib/stubs";
        };
      });
    };

  pythonSet =
    (callPackage inputs.pyproject-nix.build.packages { inherit python; }).overrideScope
      (
        lib.composeManyExtensions [
          inputs.pyproject-build-systems.overlays.default
          overlay
          overrides
        ]
      );
in
pythonSet.mkVirtualEnv "freetoken-env" workspace.deps.default
