#!/bin/sh
# Makes the Store's poster and box art: the white glyph and "A2N Hymnal" in Clash Grotesk on
# the Now Playing cover's gold (Brand.coverGradient). Needs ImageMagick.
set -eu
cd "$(dirname "$0")"
font=../../shared/src/commonMain/composeResources/font/clash_grotesk_semibold.ttf
glyph=$(mktemp -t a2n-glyph).png
magick "../../../apple/A2N Hymnal/AppIcon.icon/Assets/Glyph.png" -fill white -colorize 100 "$glyph"

# art <width> <height> <glyph size> <glyph top> <title size> <title top> <file>
art() {
    magick -size "$1x$2" -define gradient:direction=southeast gradient:'#DE991A-#8C4A0A' \
        \( "$glyph" -resize "$3x$3" \) -gravity north -geometry +0+"$4" -composite \
        -font "$font" -fill white -pointsize "$5" -gravity north -annotate +0+"$6" 'A2N Hymnal' \
        -strip "PNG24:$7"
}
art 1440 2160 900 380 170 1330 poster-9x16-1440x2160.png
art 2160 2160 1100 330 190 1470 box-art-1x1-2160x2160.png
rm -f "$glyph"
