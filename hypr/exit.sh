#!/bin/bash

options="󰜉 Reboot\n󰈆 Exit\n󰅖 Cancel"

chosen=$(echo -e "$options" | fuzzel --placeholder 'Power Menu:' --dmenu)

case "$chosen" in
"󰜉 Reboot")
  systemctl reboot
  ;;
"󰈆 Exit")
  hyprctl dispatch 'hl.dsp.exit()'
  ;;
"󰅖 Cancel")
  exit 0
  ;;
esac
