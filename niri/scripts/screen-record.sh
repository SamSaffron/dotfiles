#!/bin/bash
set -euo pipefail

PIDFILE="/tmp/wf-recorder.pid"
RECORDING_FILE_PATH="/tmp/wf-recorder-current-file"
SCREENCAST_DIR="${HOME}/Videos/Screencasts"

mkdir -p "$SCREENCAST_DIR"

stop_recording() {
  local pid recorded_file
  pid=$(<"$PIDFILE")
  kill -SIGINT "$pid" 2>/dev/null || true
  wait "$pid" 2>/dev/null || true
  rm -f "$PIDFILE"

  if [[ -f "$RECORDING_FILE_PATH" ]]; then
    recorded_file=$(<"$RECORDING_FILE_PATH")
    rm -f "$RECORDING_FILE_PATH"
    if [[ -f "$recorded_file" ]]; then
      notify-send "Screen Recording" "Recording saved to $recorded_file" -i video-x-generic
      printf 'file://%s' "$recorded_file" | wl-copy -t text/uri-list
      return
    fi
  fi

  notify-send "Screen Recording" "Failed to find recording file" -i dialog-error
}

focused_geometry() {
  command -v niri >/dev/null 2>&1 || return 1
  local json
  json=$(niri msg --json focused-window 2>/dev/null || true)
  if [[ -z "$json" || "$json" == "null" ]]; then
    return 1
  fi

  printf '%s' "$json" | jq -r '
    .layout as $layout
    | ($layout.window_size // empty) as $size
    | if ($size | length) == 2 then
        ($layout.window_offset_in_tile // [0.0, 0.0]) as $offset
        | ($layout.tile_pos_in_workspace_view // null) as $tile
        | if $tile != null then
            ($tile[0] + $offset[0]) as $x
            | ($tile[1] + $offset[1]) as $y
        else
            $offset[0] as $x
            | $offset[1] as $y
        end
        | ($x | floor) as $xf
        | ($y | floor) as $yf
        | ($size[0]) as $width
        | ($size[1]) as $height
        | ($xf | tostring) + "," + ($yf | tostring) + " " + ($width | tostring) + "x" + ($height | tostring)
      else empty end
  ' 2>/dev/null
}

if [[ -f "$PIDFILE" ]]; then
  stop_recording
  exit 0
fi

notify-send "Screen Recording" "Click to select window or drag to select region" -i media-record

recording_file="$SCREENCAST_DIR/screencast-$(date +%Y%m%d-%H%M%S).mp4"
printf '%s\n' "$recording_file" >"$RECORDING_FILE_PATH"

geometry=$(slurp 2>/dev/null || true)
if [[ -z "$geometry" || "$geometry" =~ ^0,0\ 0x0$ ]]; then
  geometry=$(focused_geometry || true)
fi

if [[ -z "$geometry" || "$geometry" =~ ^0,0\ 0x0$ ]]; then
  notify-send "Screen Recording" "No selection made" -i dialog-information
  rm -f "$RECORDING_FILE_PATH"
  exit 1
fi

wf-recorder -g "$geometry" -c h264_nvenc \
  -p preset=fast -p rc=vbr -p cq=35 -p b:v=1M -r 30 -f "$recording_file" &
printf '%s\n' "$!" >"$PIDFILE"
