#!/bin/bash

PIDFILE="/tmp/wf-recorder.pid"
RECORDING_FILE_PATH="/tmp/wf-recorder-current-file"
SCREENCAST_DIR="$HOME/Videos/Screencasts"

mkdir -p "$SCREENCAST_DIR"

if [ -f "$PIDFILE" ]; then
  PID=$(cat "$PIDFILE")
  kill -SIGINT "$PID"
  wait "$PID" 2>/dev/null

  if [ -f "$RECORDING_FILE_PATH" ]; then
    RECORDED_FILE=$(cat "$RECORDING_FILE_PATH")
    rm "$RECORDING_FILE_PATH"
  fi

  rm "$PIDFILE"

  if [ -f "$RECORDED_FILE" ]; then
    notify-send "Screen Recording" "Recording saved to $RECORDED_FILE" -i video-x-generic
  else
    notify-send "Screen Recording" "Failed to find recording file" -i dialog-error
  fi
else
  notify-send "Screen Recording" "Click to select window or drag to select region" -i media-record
  RECORDING_FILE="$SCREENCAST_DIR/screencast-$(date +%Y%m%d-%H%M%S).mp4"
  echo "$RECORDING_FILE" >"$RECORDING_FILE_PATH"

  GEOMETRY=$(slurp 2>/dev/null)

  if [ -z "$GEOMETRY" ] || [[ "$GEOMETRY" =~ ^0,0\ 0x0$ ]]; then
    GEOMETRY=$(hyprctl activewindow -j | jq -r '"\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"')
  fi

  wf-recorder -g "$GEOMETRY" -c h264_nvenc -p preset=fast -p rc=vbr -p cq=35 -p b:v=1M -r 30 -f "$RECORDING_FILE" &
  echo $! >"$PIDFILE"
fi
