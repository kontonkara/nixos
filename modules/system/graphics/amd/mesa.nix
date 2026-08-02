{ pkgs, lib, ... }:

{
  hardware = {
    graphics =
      let
        overrideMesa =
          mesa:
          (mesa.override {
            galliumDrivers = [
              "radeonsi"
              "zink"
              "llvmpipe"
            ];
            vulkanDrivers = [
              "amd"
            ];
            vulkanLayers = [
              "device-select"
              "anti-lag"
              "overlay"
            ];
            withValgrind = false;
          }).overrideAttrs
            (oldAttrs: {
              mesonFlags = oldAttrs.mesonFlags ++ [
                (pkgs.lib.mesonOption "c_args" "-march=znver4")
                (pkgs.lib.mesonOption "cpp_args" "-march=znver4")
                (pkgs.lib.mesonOption "optimization" "3")
                (pkgs.lib.mesonOption "b_ndebug" "true")
              ];

              outputs = lib.filter (out: out != "spirv2dxil") oldAttrs.outputs;
            });
      in
      {
        package = overrideMesa pkgs.mesa;
        package32 = overrideMesa pkgs.pkgsi686Linux.mesa;
      };
  };
}
