{ config, lib, pkgs, username, ... }:

let
  cfg = config.modules.home.davinci-resolve;

  # Resolve computes with CUDA and draws its UI with GLX on XWayland, and
  # wants both on the same GPU: everything goes to the RTX, the way
  # nvidia-offload sends it. The RAW player and the utilities stay as they are.
  resolve = pkgs.symlinkJoin {
    name = "davinci-resolve-offload-${pkgs.davinci-resolve.version}";
    paths = [
      pkgs.davinci-resolve
    ];
    nativeBuildInputs = [
      pkgs.makeWrapper
    ];
    postBuild = ''
      rm $out/bin/davinci-resolve
      makeWrapper ${pkgs.davinci-resolve}/bin/davinci-resolve $out/bin/davinci-resolve \
        --set __NV_PRIME_RENDER_OFFLOAD 1 \
        --set __NV_PRIME_RENDER_OFFLOAD_PROVIDER NVIDIA-G0 \
        --set __GLX_VENDOR_LIBRARY_NAME nvidia \
        --set __VK_LAYER_NV_optimus NVIDIA_only
    '';
  };
in
{
  options = {
    modules = {
      home = {
        davinci-resolve = {
          enable = lib.mkEnableOption "DaVinci Resolve";
        };
      };
    };
  };

  # The free edition. On Linux it neither decodes nor encodes H.264/H.265
  # and has no AAC: phone footage goes through DNxHR/ProRes first (ffmpeg),
  # or Studio, which uses NVDEC/NVENC. nixpkgs downloads the installer from
  # Blackmagic at build time (about 3 GB; unfree, so never in a cache).
  config = lib.mkIf cfg.enable {
    home-manager = {
      users = {
        ${username} = {
          home = {
            packages = [
              resolve
            ];
          };
        };
      };
    };
  };
}
