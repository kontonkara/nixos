_final: prev:

let
  libopenh264-cisco = prev.fetchurl {
    name = "libopenh264-2.6.0-linux64.8.so";
    url = "https://web.archive.org/web/20250220193700/http://ciscobinary.openh264.org/libopenh264-2.6.0-linux64.8.so.bz2";
    hash = "sha256-LwzefGpqvPXK52lCiU6kKJf6Z3vOTtbJGiTdGwQdXwQ=";
    downloadToTemp = true;
    nativeBuildInputs = [ prev.bzip2 ];
    postFetch = ''
      bunzip2 -c "$downloadedFile" > $out
    '';
  };

  stageOpenh264 = prev.writeShellScript "vesktop-stage-openh264" ''
    cache_dir="''${XDG_CONFIG_HOME:-$HOME/.config}/vesktop/discord_asset_cache/openh264"
    mkdir -p "$cache_dir"
    ln -sfT ${libopenh264-cisco} "$cache_dir/libopenh264-2.6.0-linux64.8.so"
  '';
in
{
  vesktop = prev.vesktop.overrideAttrs (prevAttrs: {
    postFixup = (prevAttrs.postFixup or "") + ''
      wrapProgram $out/bin/vesktop --run "${stageOpenh264}"
    '';
  });
}
