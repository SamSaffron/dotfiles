#!/bin/bash

# Options
reboot="󰜉 Reboot"
exit="󰈆 Exit"
cancel="󰅖 Cancel"

# Rofi command
chosen=$(echo -e "$exit\n$reboot\n$cancel" | rofi -dmenu -theme-str 'window {width: 20%;}' -p "Power Menu:")

case $chosen in
$reboot)
  systemctl reboot
  ;;
$exit)
  hyprctl dispatch exit
  ;;
$cancel)
  exit 0
  ;;
esac
