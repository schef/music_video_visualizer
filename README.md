# FarmFest Visualizer

This project creates FarmFest music visualizer videos from audio files.

It uses a background image, a waveform, and styled song text.

## Create a full video

```bash
./farmfest-knockout-outlined-viz.sh background.jpg track.mp3 output.mp4 "FARMFEST RAVE ŠATOR" "SONG TITLE"
```

## Make a short test video

Use `DURATION` to render only a few seconds.

```bash
DURATION=5 ./farmfest-knockout-outlined-viz.sh background.jpg track.mp3 short-test.mp4 "FARMFEST RAVE ŠATOR" "SONG TITLE"
```

You can also start later in the song with `START`.

```bash
START=30 DURATION=5 ./farmfest-knockout-outlined-viz.sh background.jpg track.mp3 short-test.mp4 "FARMFEST RAVE ŠATOR" "SONG TITLE"
```

## Generate one preview image

First render a very short video.

```bash
START=30 DURATION=1 ./farmfest-knockout-outlined-viz.sh background.jpg track.mp3 preview.mp4 "FARMFEST RAVE ŠATOR" "SONG TITLE"
```

Then extract one frame with FFmpeg.

```bash
ffmpeg -y -i preview.mp4 -frames:v 1 preview.png
```

## Current text defaults

```bash
FONT_SIZE=32
TEXT_SCALE_X=100
TEXT_LETTER_SPACING=9
TEXT_GAP=500
```

Example with explicit text settings:

```bash
FONT_SIZE=32 TEXT_SCALE_X=100 TEXT_LETTER_SPACING=9 TEXT_GAP=500 \
./farmfest-knockout-outlined-viz.sh background.jpg track.mp3 output.mp4 "FARMFEST RAVE ŠATOR" "SONG TITLE"
```

## Generate all videos

```bash
./generate-all-videos.sh
```

Videos are written to:

```bash
./videos
```
