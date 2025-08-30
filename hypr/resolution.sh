#!/bin/bash

current_scale=$(hyprctl monitors -j | jq -r '.[] | select(.name=="DP-1") | .scale')

if (($(echo "$current_scale == 1.6" | bc -l))); then
  hyprctl keyword monitor DP-1,highrr,auto,1.0
  notify-send "Display Scaling" "Switched to 100%" -t 2000
else
  hyprctl keyword monitor DP-1,highrr,auto,1.6
  notify-send "Display Scaling" "Switched to 160%" -t 2000
fi
