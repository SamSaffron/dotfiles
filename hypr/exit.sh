#!/bin/bash

options="󰜉 Reboot\n󰈆 Exit\n󰅖 Cancel"

chosen=$(echo -e "$options" | walker --placeholder 'Power Menu:' --dmenu)

case "$chosen" in
"󰜉 Reboot")
  systemctl reboot
  ;;
"󰈆 Exit")
  hyprctl dispatch exit
  ;;
"󰅖 Cancel")
  exit 0
  ;;
esac
