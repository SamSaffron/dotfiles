#!/bin/bash

focus_workspace() {
  hyprctl dispatch "hl.dsp.focus({ workspace = \"$1\" })"
}

exec_cmd() {
  local cmd_json
  cmd_json=$(jq -Rn --arg s "$1" '$s')
  hyprctl dispatch "hl.dsp.exec_cmd($cmd_json)"
}

layout_msg() {
  hyprctl dispatch "hl.dsp.layout(\"$1\")"
}

# Function to check if workspace 3 is empty
is_workspace_empty() {
  local workspace_id=3
  local window_count=$(hyprctl workspaces -j | jq ".[] | select(.id == $workspace_id) | .windows" 2>/dev/null)

  # If workspace doesn't exist or has 0 windows, it's empty
  if [[ -z "$window_count" ]] || [[ "$window_count" -eq 0 ]]; then
    return 0 # empty
  else
    return 1 # not empty
  fi
}

# Check if workspace 3 is empty
if is_workspace_empty; then
  echo "Workspace 3 is empty. Setting up editing environment..."

  # Switch to workspace 3 first
  focus_workspace 3

  # Configure master layout
  hyprctl eval 'hl.config({ general = { layout = "master" }, master = { mfact = 0.7, slave_count_for_center_master = -1, orientation = "left" } })'
  layout_msg "orientationleft"
  layout_msg "mfact exact 0.7"

  # Small delay to ensure layout is set
  sleep 0.3

  # Launch ghostty terminal with vim in discourse directory
  exec_cmd "ghostty --wait-after-command --working-directory='/home/sam/Source/discourse' -e bash -c 'vim'"

  # Small delay before launching chromium
  sleep 0.5

  # Launch chromium
  exec_cmd "chromium"

  # Notify success
  notify-send "Editing Environment" "Set up master layout with vim and chromium on workspace 3" -t 3000

else
  echo "Workspace 3 is already set up. Taking you there..."

  # Notify that workspace is already set up
  notify-send "Workspace 3 Ready" "Editing environment is already set up" -t 3000

  # Switch to workspace 3
  focus_workspace 3
fi
