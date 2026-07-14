#!/usr/bin/env bash
set -euo pipefail

# Generate FarmFest visualizer videos for all known song metadata.
#
# Defaults:
#   SONGS_DIR=./songs
#   OUT_DIR=./videos
#   BG=./background.jpg
#   VIS_SCRIPT=./farmfest-knockout-outlined-viz.sh
#   AUTHOR='FF26 RAVE ŠATOR'
#   DURATION=999999   # effectively full song; output still ends with -shortest
#
# Example:
#   ./generate-all-videos.sh
#
# Override example:
#   OUT_DIR=./renders CRF=20 PRESET=fast ./generate-all-videos.sh

SONGS_DIR="${SONGS_DIR:-./songs}"
OUT_DIR="${OUT_DIR:-./videos}"
BG="${BG:-./background.jpg}"
VIS_SCRIPT="${VIS_SCRIPT:-./farmfest-knockout-outlined-viz.sh}"
AUTHOR="${AUTHOR:-RAVE ŠATOR}"
DURATION="${DURATION:-999999}"

mkdir -p "$OUT_DIR"

slugify() {
    local text="$1"
    text="${text,,}"
    text="${text//č/c}"
    text="${text//ć/c}"
    text="${text//đ/d}"
    text="${text//š/s}"
    text="${text//ž/z}"
    text="${text// /_}"
    text="${text//,/_}"
    text="${text//\//_}"
    text="${text//__/_}"
    text="${text##_}"
    text="${text%%_}"
    printf '%s' "$text"
}

render_one() {
    local title="$1"
    shift

    local audio=""
    local candidate

    for candidate in "$@"; do
        if [[ -z "$audio" ]]; then
            if [[ -f "$SONGS_DIR/$candidate" ]]; then
                audio="$SONGS_DIR/$candidate"
            fi
        fi
    done

    if [[ -n "$audio" ]]; then
        local slug
        local output

        slug="$(slugify "$title")"
        output="$OUT_DIR/${slug}.mp4"

        echo "Rendering: $title"
        echo "  Audio:  $audio"
        echo "  Output: $output"

        DURATION="$DURATION" \
            "$VIS_SCRIPT" "$BG" "$audio" "$output" "$AUTHOR" "$title"
    else
        echo "Skipping missing audio: $title" >&2
        echo "  Tried:" >&2
        for candidate in "$@"; do
            echo "    $SONGS_DIR/$candidate" >&2
        done
    fi
}

render_one "AKO SAM DUŠU NEKU RANIO" \
    "ako_sam_koju_dusu_ranio.mp3"

render_one "BIJEL KO SNIJEG" \
    "bijel_ko_snijeg.mp3"

render_one "HALELUJA PRIČA" \
    "haleluja_prica.mp3"

render_one "PRIČAJ MI O ISUSU" \
    "pricaj_mi_o_isusu.mp3"

render_one "PUSTINJA" \
    "pustinja.mp3"

render_one "TVOJE NEBO" \
    "tvoje_nebo.mp3"

render_one "TVORAC / DOVRŠITELJ" \
    "tvorac_i_dovrsitelj.mp3"

render_one "ZNAM" \
    "znam.mp3"

echo "Done. Videos are in: $OUT_DIR"
