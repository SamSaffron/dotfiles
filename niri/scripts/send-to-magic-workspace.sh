#!/bin/bash
set -euo pipefail

command -v niri >/dev/null 2>&1 || exit 0

current_idx=$(niri msg --json workspaces 2>/dev/null | jq -r '.[] | select(.is_focused) | .idx' 2>/dev/null || true)

if niri msg action move-window-to-workspace magic --focus false >/dev/null 2>&1; then
  exit 0
fi

# If the workspace does not exist yet, create it and retry.
niri msg action focus-workspace magic >/dev/null 2>&1 || true
niri msg action set-workspace-name magic >/dev/null 2>&1 || true

if [[ -n "$current_idx" ]]; then
  niri msg action focus-workspace "$current_idx" >/dev/null 2>&1 || true
fi

niri msg action move-window-to-workspace magic --focus false >/dev/null 2>&1 || true
