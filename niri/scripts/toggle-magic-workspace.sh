#!/bin/bash
set -euo pipefail

command -v niri >/dev/null 2>&1 || exit 0

current=$(niri msg --json workspaces 2>/dev/null | jq -r '.[] | select(.is_focused) | (.name // ("#" + (.idx|tostring)))' 2>/dev/null || true)

if [[ "$current" == "magic" ]]; then
  niri msg action focus-workspace-previous >/dev/null 2>&1 || true
else
  niri msg action focus-workspace magic >/dev/null 2>&1 || true
fi
