{ runCommand, fetchurl, imagemagick, zip }:

# Catppuccin Mocha for Telegram Desktop with the Peach accent. Upstream only
# publishes cloud themes (t.me/addtheme/ctp_mocha, green accent); its source
# palette isn't loadable as is: header lines, and no ';' after the values.
let
  palette = fetchurl {
    url = "https://raw.githubusercontent.com/catppuccin/telegram/25e4ddb6d16694b46ff7a90d41cce2372ab4c25b/src/mocha/desktop";
    hash = "sha256-FgLf0Rpt9XOlXdiciJywAg6zmRKiQEA4CffMsEUH8DU=";
  };
in
runCommand "catppuccin-mocha-peach.tdesktop-theme"
  {
    nativeBuildInputs = [
      imagemagick
      zip
    ];
  }
  ''
    # Also fixes upstream's misspelled cptText/cptRed/windowSubtextFg, which
    # Telegram would skip.
    sed -E \
      -e '/^(name|shortname|dark|wallpaper):/d' \
      -e 's#^([A-Za-z0-9_]+):[[:space:]]*(\#?[A-Za-z0-9_]+);?[[:space:]]*(//.*)?$#\1: \2; \3#' \
      -e 's#^ctpAccent: ctpGreen;#ctpAccent: ctpPeach;#' \
      -e 's#: cpt([A-Za-z]+);#: ctp\1;#' \
      -e 's#: windowSubtextFg;#: windowSubTextFg;#' \
      -e 's#[[:space:]]+$##' \
      ${palette} > colors.tdesktop-theme
    grep -qx 'ctpAccent: ctpPeach;' colors.tdesktop-theme

    # Upstream's cloud wallpaper is plain Crust. Without a background Telegram
    # falls back to its patterned default.
    magick -size 64x64 xc:'#11111b' PNG24:tiled.png

    touch -d '1980-01-02 00:00:00' colors.tdesktop-theme tiled.png
    zip -X -q theme.zip colors.tdesktop-theme tiled.png
    mv theme.zip $out
  ''
