#!/bin/sh
# Makes the Store package's icons (msix/Assets) from the app glyph: the same white rounded
# square as the Windows icon (icons/hymnal.ico), on a transparent background so Windows shows
# it unplated. Needs ImageMagick. Run it again only when the glyph changes.
set -eu
cd "$(dirname "$0")"
glyph="../../../apple/A2N Hymnal/AppIcon.icon/Assets/Glyph.png"
out=Assets
mkdir -p "$out"

# icon <size> <file>: the rounded square at size×size, as in icon.png (12/256 margin).
icon() {
    s=$1
    m=$(( s * 12 / 256 )); r=$(( s * 52 / 256 )); g=$(( s * 226 / 256 ))
    magick -size "${s}x${s}" xc:none \
        -fill white -stroke 'rgba(148,148,148,0.35)' -strokewidth "$(( s / 256 + 1 ))" \
        -draw "roundrectangle $m,$m $((s - m - 1)),$((s - m - 1)) $r,$r" \
        \( "$glyph" -resize "${g}x${g}" \) -gravity center -composite \
        -strip "PNG32:$2"
}

for scale in 100 125 150 200 400; do
    icon $(( 44 * scale / 100 )) "$out/Square44x44Logo.scale-$scale.png"
    icon $(( 150 * scale / 100 )) "$out/Square150x150Logo.scale-$scale.png"
    icon $(( 50 * scale / 100 )) "$out/StoreLogo.scale-$scale.png"
    # The wide tile: the square icon centred, at the tile's height.
    w=$(( 310 * scale / 100 )); h=$(( 150 * scale / 100 ))
    icon "$h" /tmp/a2n-wide.png
    magick -size "${w}x${h}" xc:none /tmp/a2n-wide.png -gravity center -composite -strip "PNG32:$out/Wide310x150Logo.scale-$scale.png"
done
# Taskbar, Start and File Explorer sizes, drawn as they are rather than on a coloured plate.
for t in 16 20 24 30 32 36 40 48 60 64 72 80 96 256; do
    icon "$t" "$out/Square44x44Logo.targetsize-$t.png"
    cp "$out/Square44x44Logo.targetsize-$t.png" "$out/Square44x44Logo.targetsize-${t}_altform-unplated.png"
    cp "$out/Square44x44Logo.targetsize-$t.png" "$out/Square44x44Logo.targetsize-${t}_altform-lightunplated.png"
done
rm -f /tmp/a2n-wide.png
