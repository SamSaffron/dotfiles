#!/bin/bash
set -euo pipefail

dir="$HOME"

if command -v niri >/dev/null 2>&1; then
  focused_json=$(niri msg --json focused-window 2>/dev/null || true)
  if [[ -n "$focused_json" && "$focused_json" != "null" ]]; then
    pid=$(printf '%s' "$focused_json" | jq -r '.pid // empty' 2>/dev/null || true)
    if [[ -n "$pid" && "$pid" =~ ^[0-9]+$ && "$pid" -gt 1 ]]; then
      shell_pid=$(pstree -aApT "$pid" 2>/dev/null | grep -E 'zsh,|bash,' | head -1 | awk -F',' '{print $NF}')
      if [[ -n "$shell_pid" && "$shell_pid" =~ ^[0-9]+$ ]]; then
        cwd=$(readlink "/proc/$shell_pid/cwd" 2>/dev/null || true)
        if [[ -n "$cwd" && -d "$cwd" && "$cwd" != *"'"* ]]; then
          dir="$cwd"
        fi
      fi
    fi
  fi
fi

cd "$dir"
exec kitty
