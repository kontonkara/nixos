{ config, lib, pkgs, username, ... }:

let
  cfg = config.modules.home.artcraft;

  # The apps draw with wgpu, whose adapter search loads every Vulkan ICD,
  # and the NVIDIA one pulls the RTX out of D3cold (as in zed). They stay on
  # the iGPU; their CLIs (wordcraft-cli and the like) draw nothing.
  onIgpu =
    app:
    pkgs.symlinkJoin {
      name = "${app.pname}-igpu-${app.version}";
      paths = [
        app
      ];
      nativeBuildInputs = [
        pkgs.makeWrapper
      ];
      postBuild = ''
        rm $out/bin/${app.pname}
        makeWrapper ${app}/bin/${app.pname} $out/bin/${app.pname} \
          --set VK_LOADER_DRIVERS_DISABLE '*nvidia*' \
          --set __NV_PRIME_RENDER_OFFLOAD 0
      '';
    };
in
{
  options = {
    modules = {
      home = {
        artcraft = {
          enable = lib.mkEnableOption "the ArtCraft app suite";
        };
      };
    };
  };

  # WordCraft, GridCraft and DeckCraft (DOCX/ODT, XLSX, PPTX), plus SoundCraft
  # (a multitrack DAW). Pre-alpha: open copies, not the originals.
  config = lib.mkIf cfg.enable {
    home-manager = {
      users = {
        ${username} = {
          home = {
            packages = map onIgpu [
              pkgs.wordcraft
              pkgs.gridcraft
              pkgs.deckcraft
              pkgs.soundcraft
            ];
          };
        };
      };
    };
  };
}
