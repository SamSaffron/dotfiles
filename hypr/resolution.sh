#!/bin/bash

current_scale=$(hyprctl monitors -j | jq -r '.[] | select(.name=="DP-1") | .scale')

# Cycle normal, desktop, and presentation/recording scales.
case "$current_scale" in
  1.6)
    next_scale=2.5
    percentage=250
    ;;
  2.5)
    next_scale=1.0
    percentage=100
    ;;
  *)
    next_scale=1.6
    percentage=160
    ;;
esac

hyprctl eval "hl.monitor({ output = \"DP-1\", mode = \"highrr\", position = \"auto\", scale = $next_scale })"
notify-send "Display Scaling" "Switched to $percentage%" -t 2000
