#!/bin/bash

options="󰜉 Reboot\n󰈆 Exit\n󰅖 Cancel"

chosen=$(echo -e "$options" | walker -H --placeholder 'Power Menu:' --dmenu --label 1 --separator '\n')

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
