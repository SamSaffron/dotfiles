#!/bin/bash

focus_workspace() {
  hyprctl dispatch "hl.dsp.focus({ workspace = \"$1\" })"
}

exec_cmd() {
  local cmd_json
  cmd_json=$(jq -Rn --arg s "$1" '$s')
  hyprctl dispatch "hl.dsp.exec_cmd($cmd_json)"
}

# Function to check if workspace 2 is empty
is_workspace_empty() {
  local workspace_id=2
  local window_count=$(hyprctl workspaces -j | jq ".[] | select(.id == $workspace_id) | .windows" 2>/dev/null)

  # If workspace doesn't exist or has 0 windows, it's empty
  if [[ -z "$window_count" ]] || [[ "$window_count" -eq 0 ]]; then
    return 0 # empty
  else
    return 1 # not empty
  fi
}

# Check if workspace 2 is empty
if is_workspace_empty; then
  echo "Workspace 2 is empty. Setting up Discourse development environment..."

  # Switch to workspace 2 first
  focus_workspace 2

  # Launch first ghostty terminal for unicorn
  exec_cmd "ghostty --wait-after-command -e bash -c 'cd ~/Source/discourse && bin/unicorn'"

  # Small delay to ensure first terminal is launched
  sleep 0.5

  # Launch second ghostty terminal for ember-cli
  exec_cmd "ghostty --wait-after-command -e bash -c 'cd ~/Source/discourse && bin/ember-cli'"

  # Notify success
  notify-send "Discourse Dev Setup" "Launched unicorn and ember-cli terminals on workspace 2" -t 3000

else
  echo "Workspace 2 is not empty. Taking you there..."

  # Notify that workspace is not empty
  notify-send "Workspace 2 Not Empty" "Workspace 2 already has applications running" -t 3000

  # Switch to workspace 2 so user can see what's there
  focus_workspace 2
fi
