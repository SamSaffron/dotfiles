#!/bin/bash

PIDFILE="/tmp/gpu-screen-recorder.pid"
RECORDING_FILE_PATH="/tmp/gpu-screen-recorder-current-file"
SCREENCAST_DIR="$HOME/Videos/Screencasts"
LOGFILE="/tmp/gpu-screen-recorder.log"

mkdir -p "$SCREENCAST_DIR"

if [ -f "$PIDFILE" ]; then
  PID=$(cat "$PIDFILE")
  notify-send "Screen Recording" "Stopping recording…" -i media-record
  kill -SIGINT "$PID"
  # The recorder was started by a previous invocation, so it is not our child.
  # Wait for it to finish writing the video before announcing/copying the file.
  for ((attempt = 0; attempt < 100; attempt++)); do
    kill -0 "$PID" 2>/dev/null || break
    sleep 0.1
  done
  if kill -0 "$PID" 2>/dev/null; then
    notify-send "Screen Recording" "Still finishing recording. Try again shortly." -i dialog-information
    exit 1
  fi

  if [ -f "$RECORDING_FILE_PATH" ]; then
    RECORDED_FILE=$(cat "$RECORDING_FILE_PATH")
    rm "$RECORDING_FILE_PATH"
  fi

  rm "$PIDFILE"

  if [ -f "$RECORDED_FILE" ]; then
    notify-send "Screen Recording" "Recording saved to $RECORDED_FILE" -i video-x-generic
    echo "file://$RECORDED_FILE" | wl-copy -t text/uri-list
  else
    notify-send "Screen Recording" "Failed to find recording file" -i dialog-error
  fi
else
  RECORDING_FILE="$SCREENCAST_DIR/screencast-$(date +%Y%m%d-%H%M%S).mp4"
  echo "$RECORDING_FILE" >"$RECORDING_FILE_PATH"

  if [ "${1:-}" = "--fullscreen" ]; then
    notify-send "Screen Recording" "Starting whole-screen recording" -i media-record
    GEOMETRY="screen"
  else
    notify-send "Screen Recording" "Click to select window or drag to select region" -i media-record
    GEOMETRY=$(slurp 2>/dev/null)

    if [ -z "$GEOMETRY" ] || [[ "$GEOMETRY" =~ ^0,0\ 0x0$ ]]; then
      GEOMETRY=$(hyprctl activewindow -j | jq -r '"\(.size[0])x\(.size[1])+\(.at[0])+\(.at[1])"')
    else
      # Convert slurp format "X,Y WxH" to gpu-screen-recorder format "WxH+X+Y"
      GEOMETRY=$(echo "$GEOMETRY" | sed 's/\([0-9]*\),\([0-9]*\) \([0-9]*\)x\([0-9]*\)/\3x\4+\1+\2/')
    fi
  fi

  # Cap output size for H.264, preserving aspect ratio on ultrawide displays.
  gpu-screen-recorder -w "$GEOMETRY" -s 3840x2160 -f 30 -k h264 -q medium -o "$RECORDING_FILE" >"$LOGFILE" 2>&1 &
  GSR_PID=$!
  sleep 1

  if kill -0 "$GSR_PID" 2>/dev/null; then
    echo "$GSR_PID" >"$PIDFILE"
    notify-send "Screen Recording" "Recording started" -i media-record
  else
    rm -f "$RECORDING_FILE_PATH"
    notify-send "Screen Recording" "gpu-screen-recorder failed to start. Check $LOGFILE" -i dialog-error
  fi
fi
