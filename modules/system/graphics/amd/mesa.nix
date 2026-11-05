{ config, pkgs, lib, ... }:

let
  cfg = config.modules.system.graphics.amd;
  ccache = config.modules.system.ccache;
in
{
  config = lib.mkIf cfg.enable {
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
                mesonFlags =
                  oldAttrs.mesonFlags
                  ++ lib.optionals (cfg.mesa.cpuArch != null) [
                    (pkgs.lib.mesonOption "c_args" "-march=${cfg.mesa.cpuArch}")
                    (pkgs.lib.mesonOption "cpp_args" "-march=${cfg.mesa.cpuArch}")
                  ]
                  ++ lib.optional (cfg.mesa.optimizationLevel != null) (
                    pkgs.lib.mesonOption "optimization" (toString cfg.mesa.optimizationLevel)
                  )
                  ++ lib.optional cfg.mesa.disableAssertions (pkgs.lib.mesonOption "b_ndebug" "true");

                outputs = lib.filter (out: out != "spirv2dxil") oldAttrs.outputs;
              });
        in
        {
          # ccache only for the 64-bit build.
          package = overrideMesa (pkgs.mesa.override (
            lib.optionalAttrs ccache.enable { stdenv = ccache.wrapStdenv pkgs.mesa.stdenv; }
          ));
          package32 = overrideMesa pkgs.pkgsi686Linux.mesa;
        };
    };
  };
}
