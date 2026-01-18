#!/bin/bash

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
  hyprctl dispatch workspace 2

  # Launch first ghostty terminal for unicorn
  hyprctl dispatch exec "ghostty --wait-after-command -e bash -c 'cd ~/Source/discourse && bin/unicorn'"

  # Small delay to ensure first terminal is launched
  sleep 0.5

  # Launch second ghostty terminal for ember-cli
  hyprctl dispatch exec "ghostty --wait-after-command -e bash -c 'cd ~/Source/discourse && bin/ember-cli'"

  # Notify success
  notify-send "Discourse Dev Setup" "Launched unicorn and ember-cli terminals on workspace 2" -t 3000

else
  echo "Workspace 2 is not empty. Taking you there..."

  # Notify that workspace is not empty
  notify-send "Workspace 2 Not Empty" "Workspace 2 already has applications running" -t 3000

  # Switch to workspace 2 so user can see what's there
  hyprctl dispatch workspace 2
fi
