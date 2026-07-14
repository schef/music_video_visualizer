#!/usr/bin/env bash
set -euo pipefail

# farmfest-knockout-outlined-viz.sh
#
# 16:9 techno visualizer:
# - full artwork preserved using blurred 16:9 side fill
# - mirrored center-out bass spectrum
# - FarmFest-style filled author/song text
# - author text: white
# - song title text: black
# - no rectangle around the text
#
# Usage:
#   ./farmfest-knockout-outlined-viz.sh \
#       background.jpg track.mp3 output.mp4 "Author Name" "Song Name"
#
# FarmFest lower-text style defaults:
#   FONT_SIZE=32
#   TEXT_PADDING=0
#   TEXT_UPPERCASE=1
#   TEXT_TRACKING=0
#
# Optional environment variables:
#   START=0
#   DURATION=10
#   WIDTH=1920
#   HEIGHT=1080
#   FPS=60
#   BASS_LOW=28
#   BASS_HIGH=220
#   GAIN=4.5
#   VIS_HEIGHT=250
#   CENTER_Y=540
#   BAR_ALPHA=0.58
#   GLOW_ALPHA=0.28
#   FONT_SIZE=32
#   TEXT_PADDING=0
#   TEXT_GAP=500
#   FONT_FILE=/path/to/font.ttf
#   FONT_NAME='Cocogoose Pro'
#   TEXT_UPPERCASE=1
#   TEXT_TRACKING=0
#   TEXT_SCALE_X=100
#   TEXT_LETTER_SPACING=9
#   WORD_SPACING=3
#   CRF=18
#   PRESET=medium

BG="${1:-background.jpg}"
AUDIO="${2:-track.mp3}"
OUTPUT="${3:-farmfest-knockout-outlined.mp4}"
AUTHOR="${4:-Author Name}"
SONG="${5:-Song Name}"

START="${START:-0}"
DURATION="${DURATION:-10}"
WIDTH="${WIDTH:-1920}"
HEIGHT="${HEIGHT:-1080}"
FPS="${FPS:-60}"

BASS_LOW="${BASS_LOW:-28}"
BASS_HIGH="${BASS_HIGH:-220}"
GAIN="${GAIN:-4.5}"

VIS_HEIGHT="${VIS_HEIGHT:-250}"
CENTER_Y="${CENTER_Y:-540}"

BAR_ALPHA="${BAR_ALPHA:-0.58}"
GLOW_ALPHA="${GLOW_ALPHA:-0.28}"

FONT_SIZE="${FONT_SIZE:-32}"
TEXT_PADDING="${TEXT_PADDING:-0}"
OUTLINE_WIDTH="${OUTLINE_WIDTH:-0}"
TEXT_GAP="${TEXT_GAP:-500}"
FONT_FILE="${FONT_FILE:-}"
FONT_NAME="${FONT_NAME:-Cocogoose Pro}"
TEXT_UPPERCASE="${TEXT_UPPERCASE:-1}"
TEXT_TRACKING="${TEXT_TRACKING:-0}"
TEXT_SCALE_X="${TEXT_SCALE_X:-100}"
TEXT_LETTER_SPACING="${TEXT_LETTER_SPACING:-9}"
WORD_SPACING="${WORD_SPACING:-3}"

CRF="${CRF:-18}"
PRESET="${PRESET:-medium}"

if [[ ! "$TEXT_TRACKING" =~ ^[0-9]+$ ]]; then
    echo "Error: TEXT_TRACKING must be a whole number of spaces, for example 0, 1, 2, or 3." >&2
    exit 1
fi

if [[ ! "$WORD_SPACING" =~ ^[0-9]+$ ]]; then
    echo "Error: WORD_SPACING must be a whole number of spaces, for example 1, 3, 5, or 7." >&2
    exit 1
fi

if [[ ! "$TEXT_LETTER_SPACING" =~ ^[0-9]+$ ]]; then
    echo "Error: TEXT_LETTER_SPACING must be a whole-number pixel value, for example 12." >&2
    exit 1
fi

if [[ ! "$TEXT_SCALE_X" =~ ^[0-9]+$ ]]; then
    echo "Error: TEXT_SCALE_X must be a whole-number percentage, for example 100." >&2
    exit 1
fi

HALF_WIDTH=$((WIDTH / 2 - 100))
TEXT_LAYER_WIDTH=$((WIDTH * TEXT_SCALE_X / 100))
WAVE_TOP=$((CENTER_Y - VIS_HEIGHT))
TEXT_Y=$((CENTER_Y - FONT_SIZE / 2 - 6))
AUTHOR_OFFSET=$((TEXT_GAP / 2))
SONG_OFFSET=$((TEXT_GAP / 2))

command -v ffmpeg >/dev/null 2>&1 || {
    echo "Error: ffmpeg is not installed." >&2
    exit 1
}

command -v magick >/dev/null 2>&1 || {
    echo "Error: ImageMagick 'magick' is not installed. It is required for exact pixel letter spacing." >&2
    exit 1
}

[[ -f "$BG" ]] || {
    echo "Error: background image not found: $BG" >&2
    exit 1
}

[[ -f "$AUDIO" ]] || {
    echo "Error: audio file not found: $AUDIO" >&2
    exit 1
}

TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

AUTHOR_FILE="$TMPDIR/author.txt"
SONG_FILE="$TMPDIR/song.txt"
TEXT_LAYER_PNG="$TMPDIR/text-layer.png"
AUTHOR_PNG="$TMPDIR/author.png"
SONG_PNG="$TMPDIR/song.png"

stylize_farmfest_text() {
    local text="$1"

    if [[ "$TEXT_UPPERCASE" == "1" ]]; then
        text="${text^^}"
    fi

    printf '%s\n' "$text"
}

AUTHOR_TEXT="$(stylize_farmfest_text "$AUTHOR")"
SONG_TEXT="$(stylize_farmfest_text "$SONG")"

printf '%s\n' "$AUTHOR_TEXT" > "$AUTHOR_FILE"
printf '%s\n' "$SONG_TEXT" > "$SONG_FILE"

if [[ -z "$FONT_FILE" && -f "Cocogoose Pro-trial.ttf" ]]; then
    FONT_FILE="Cocogoose Pro-trial.ttf"
fi

if [[ -z "$FONT_FILE" && -f "Montserrat-ExtraBold.ttf" ]]; then
    FONT_FILE="Montserrat-ExtraBold.ttf"
fi

if [[ -n "$FONT_FILE" ]]; then
    [[ -f "$FONT_FILE" ]] || {
        echo "Error: FONT_FILE not found: $FONT_FILE" >&2
        exit 1
    }
else
    echo "Error: FONT_FILE is required for ImageMagick text rendering." >&2
    exit 1
fi

magick -background none -fill white -font "$FONT_FILE" -pointsize "$FONT_SIZE" -kerning "$TEXT_LETTER_SPACING" label:@"$AUTHOR_FILE" "$AUTHOR_PNG"
magick -background none -fill black -font "$FONT_FILE" -pointsize "$FONT_SIZE" -kerning "$TEXT_LETTER_SPACING" label:@"$SONG_FILE" "$SONG_PNG"

read -r AUTHOR_W AUTHOR_H < <(magick identify -format '%w %h\n' "$AUTHOR_PNG")
AUTHOR_X=$((WIDTH / 2 - AUTHOR_OFFSET - AUTHOR_W))
SONG_X=$((WIDTH / 2 + SONG_OFFSET))

magick -size "${WIDTH}x${HEIGHT}" canvas:none \
    "$AUTHOR_PNG" -geometry "+${AUTHOR_X}+${TEXT_Y}" -composite \
    "$SONG_PNG" -geometry "+${SONG_X}+${TEXT_Y}" -composite \
    "$TEXT_LAYER_PNG"

ffmpeg -hide_banner -loglevel warning -y \
    -loop 1 -framerate "$FPS" -i "$BG" \
    -ss "$START" -t "$DURATION" -i "$AUDIO" \
    -loop 1 -framerate "$FPS" -i "$TEXT_LAYER_PNG" \
    -filter_complex "
[0:v]
split=2[bgfill][art];

[bgfill]
scale=${WIDTH}:${HEIGHT}:force_original_aspect_ratio=increase,
crop=${WIDTH}:${HEIGHT},
gblur=sigma=28,
eq=brightness=-0.28:saturation=0.78:contrast=1.04,
format=rgba[blurred];

[art]
scale=${WIDTH}:${HEIGHT}:force_original_aspect_ratio=decrease,
format=rgba[artfit];

[blurred][artfit]
overlay=(W-w)/2:(H-h)/2[bgbase];

[1:a]
aformat=channel_layouts=stereo,
highpass=f=${BASS_LOW},
lowpass=f=${BASS_HIGH},
volume=${GAIN},
showfreqs=
s=${HALF_WIDTH}x${VIS_HEIGHT}:
mode=bar:
ascale=log:
fscale=log:
win_size=4096:
win_func=hann:
overlap=0.90:
rate=${FPS}:
colors=0xbaff00|0x00ff99,
format=rgba,
split=2[leftsrc][rightsrc];

[leftsrc]
hflip[left];

[left][rightsrc]
hstack=inputs=2[horizontal];

[horizontal]
split=2[upper][lowersrc];

[lowersrc]
vflip[lower];

[upper][lower]
vstack=inputs=2,
split=2[sharpbase][glowbase];

[sharpbase]
colorchannelmixer=aa=${BAR_ALPHA}[sharp];

[glowbase]
gblur=sigma=20,
colorchannelmixer=aa=${GLOW_ALPHA}[glow];

[bgbase][glow]
overlay=(W-w)/2:${WAVE_TOP}[withglow];

[withglow][sharp]
overlay=(W-w)/2:${WAVE_TOP}[withwave];

[2:v]
format=rgba,
scale=${TEXT_LAYER_WIDTH}:${HEIGHT}[textlayer];

[withwave][textlayer]
overlay=(W-w)/2:0,
format=yuv420p[v]
" \
    -map "[v]" \
    -map 1:a \
    -c:v libx264 \
    -preset "$PRESET" \
    -crf "$CRF" \
    -pix_fmt yuv420p \
    -r "$FPS" \
    -c:a aac \
    -b:a 320k \
    -shortest \
    -movflags +faststart \
    "$OUTPUT"

echo "Created: $OUTPUT"
echo "Resolution: ${WIDTH}x${HEIGHT}"
echo "Author text: white"
echo "Song text: black"
echo "Defaults: FONT_SIZE=${FONT_SIZE}, TEXT_SCALE_X=${TEXT_SCALE_X}, TEXT_LETTER_SPACING=${TEXT_LETTER_SPACING}px"
