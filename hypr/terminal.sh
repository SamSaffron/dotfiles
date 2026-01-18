#!/bin/bash

active_pid=$(hyprctl activewindow | grep -E "^\s*pid:" | awk '{print $2}')

dir="$HOME"

if [[ -n "$active_pid" ]] && [[ "$active_pid" =~ ^[0-9]+$ ]] && [[ "$active_pid" -gt 0 ]]; then
  # Find shell processes in the process tree
  shell_pid=$(pstree -aApT "$active_pid" 2>/dev/null | grep -E 'zsh,|bash,' | head -1 | awk -F',' '{print $NF}')

  # If we found a shell PID, get its working directory
  if [[ -n "$shell_pid" ]] && [[ "$shell_pid" =~ ^[0-9]+$ ]]; then
    cwd=$(readlink "/proc/$shell_pid/cwd" 2>/dev/null)

    # Use the directory if it exists and doesn't contain single quotes
    if [[ -n "$cwd" ]] && [[ -d "$cwd" ]] && [[ ! "$cwd" =~ \' ]]; then
      dir="$cwd"
    fi
  fi
fi

cd "$dir" && ghostty
