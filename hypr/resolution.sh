#!/bin/bash

# Get current scaling for DP-1 monitor
current_scale=$(hyprctl monitors -j | jq -r '.[] | select(.name=="DP-1") | .scale')

# Toggle between 1.0 and 1.25
if (($(echo "$current_scale == 1.25" | bc -l))); then
  # Currently at 125%, switch to 100%
  hyprctl keyword monitor DP-1,highrr,auto,1.0
  notify-send "Display Scaling" "Switched to 100%" -t 2000
else
  # Currently at 100% (or other), switch to 125%
  hyprctl keyword monitor DP-1,highrr,auto,1.25
  notify-send "Display Scaling" "Switched to 125%" -t 2000
fi
