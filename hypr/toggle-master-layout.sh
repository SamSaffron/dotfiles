#!/bin/bash

# Get current orientation
current_orientation=$(hyprctl getoption master:orientation | grep -oP 'str: \K\w+')
echo "Current orientation: $current_orientation"

# Toggle between left (2-window) and center (3-window) layouts
if [ "$current_orientation" = "center" ]; then
  hyprctl keyword master:mfact 0.6
  hyprctl keyword master:slave_count_for_center_master -1
  hyprctl keyword master:orientation left
  hyprctl dispatch layoutmsg orientationleft
  hyprctl dispatch layoutmsg mfact exact 0.6
  echo "Switched to 2-window layout (left orientation)"
else
  # Currently in left orientation, switch to center
  hyprctl keyword master:mfact 0.4
  hyprctl keyword master:slave_count_for_center_master 0
  hyprctl keyword master:orientation center
  hyprctl dispatch layoutmsg orientationcenter
  hyprctl dispatch layoutmsg mfact exact 0.4
  echo "Switched to 3-window layout (center orientation)"
fi
