#!/bin/bash
set -euo pipefail

options=$'󰜉 Reboot\n󰈆 Exit\n󰅖 Cancel'

choice=$(printf '%s' "$options" | fuzzel --placeholder 'Power Menu:' --dmenu || true)

case "$choice" in
  "󰜉 Reboot")
    systemctl reboot
    ;;
  "󰈆 Exit")
    niri msg action quit --skip-confirmation >/dev/null 2>&1 || true
    ;;
  *)
    ;;
esac
