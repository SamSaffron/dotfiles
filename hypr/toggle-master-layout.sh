#!/bin/bash

# Get current workspace
workspace=$(hyprctl activeworkspace -j | jq -r '.id')

# Get current workspace layout
workspace_layout=$(hyprctl activeworkspace -j | jq -r '.lastwindow' | xargs -I {} hyprctl clients -j | jq -r ".[] | select(.address == \"{}\") | .workspace.name")
current_layout=$(hyprctl activeworkspace -j | jq -r '.name')

# Check if workspace has custom layout by trying to get layout messages
# We'll track state in a temporary file per workspace
state_file="/tmp/hypr-layout-state-ws${workspace}"

if [ ! -f "$state_file" ]; then
  echo "master-center" > "$state_file"
fi

current_state=$(cat "$state_file")

if [ "$current_state" = "dwindle" ]; then
  # Switch to master left
  hyprctl dispatch layoutmsg orientationleft
  hyprctl dispatch layoutmsg mfact exact 0.6
  echo "master-left" > "$state_file"
  echo "Switched to 2-window layout (left orientation)"
  notify-send -t 1000 "Layout: Master Left" "2-window layout"
elif [ "$current_state" = "master-left" ]; then
  # Switch to master center
  hyprctl dispatch layoutmsg orientationcenter
  hyprctl dispatch layoutmsg mfact exact 0.4
  echo "master-center" > "$state_file"
  echo "Switched to 3-window layout (center orientation)"
  notify-send -t 1000 "Layout: Master Center" "3-window layout"
else
  # Switch back to dwindle (reset to default)
  hyprctl dispatch layoutmsg orientationleft
  hyprctl dispatch layoutmsg mfact exact 0.5
  echo "dwindle" > "$state_file"
  echo "Switched to dwindle layout"
  notify-send -t 1000 "Layout: Dwindle" "Tiling layout"
fi
