#!/bin/bash

# Get current layout
current_layout=$(hyprctl getoption general:layout | grep -oP 'str: \K\w+')

# If we're in dwindle, switch to master left
if [ "$current_layout" = "dwindle" ]; then
  hyprctl keyword general:layout master
  hyprctl keyword master:mfact 0.6
  hyprctl keyword master:slave_count_for_center_master -1
  hyprctl keyword master:orientation left
  hyprctl dispatch layoutmsg orientationleft
  hyprctl dispatch layoutmsg mfact exact 0.6
  echo "Switched to 2-window layout (left orientation)"
  notify-send -t 1000 "Layout: Master Left" "2-window layout"
else
  # We're in master layout, check orientation
  current_orientation=$(hyprctl getoption master:orientation | grep -oP 'str: \K\w+')
  echo "Current orientation: $current_orientation"

  if [ "$current_orientation" = "center" ]; then
    # Switch from center to dwindle
    hyprctl keyword general:layout dwindle
    echo "Switched to dwindle layout"
    notify-send -t 1000 "Layout: Dwindle" "Tiling layout"
  else
    # Switch from left to center
    hyprctl keyword master:mfact 0.4
    hyprctl keyword master:slave_count_for_center_master 0
    hyprctl keyword master:orientation center
    hyprctl dispatch layoutmsg orientationcenter
    hyprctl dispatch layoutmsg mfact exact 0.4
    echo "Switched to 3-window layout (center orientation)"
    notify-send -t 1000 "Layout: Master Center" "3-window layout"
  fi
fi
