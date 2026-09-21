# Quickshell Hyprland trial

A full-shell A/B test against the existing Waybar + Fuzzel + Dunst setup. The
colors, typography, modules, and bottom placement intentionally remain close to
the current bar; the difference is the integrated motion and interaction:

- animated Hyprland workspaces and active-window title
- system metrics, update count, Sydney weather, PipeWire volume, and tray
- cached ChatGPT, Claude, OpenCode Go, and Cursor subscription usage
- searchable application launcher (`Super+D`)
- searchable live window overview with workspace filtering (`Super+W`)
- control center with controls, notification history, native MPRIS media, and metrics (`Super+C`)
- minimal native System Help chat using the term-llm CLI (`Super+Shift+H`)
- native top-right notification popups, unread state, and do-not-disturb mode
- one-click return to the current setup

The config targets the stable **Quickshell v0.3.0** API.

## Try it

Quickshell is not currently installed on this machine. On Arch Linux:

```sh
sudo pacman -S quickshell
~/.config/hypr/shell-mode quickshell
```

Switch back immediately with:

```sh
~/.config/hypr/shell-mode current
```

Or alternate between the two:

```sh
~/.config/hypr/shell-mode toggle
```

The selected mode persists in `$XDG_STATE_HOME/hypr/shell-mode`. `current` is
the default, and startup automatically falls back to it if Quickshell is not
installed. This config lives below `hypr/` rather than the conventional
`~/.config/quickshell/` at your request, so the scripts launch it using `qs -p`.

## Useful commands

```sh
~/.config/hypr/shell-mode status
qs -p ~/.config/hypr/quickshell/shell.qml ipc call shell toggleLauncher
qs -p ~/.config/hypr/quickshell/shell.qml ipc call shell toggleOverview
qs -p ~/.config/hypr/quickshell/shell.qml ipc call shell toggleControlCenter
~/.config/hypr/shell-system-help
tail -f ~/.local/state/quickshell/hypr-shell.log
```

Optional commands used by individual widgets are `checkupdates`, `curl`,
`playerctl`, `nmcli`, `bluetoothctl`, `brightnessctl`, `wdisplays`, `nvidia-smi`,
`btop`, `dust`, `yay`, `docker`, and `pavucontrol`/`helvum`. Missing optional commands only
disable their associated widget or action. Per-process NVIDIA attribution additionally
uses the optional `python-nvidia-ml-py` package. `term-llm` powers the LLM usage panel; its normalized quota
summary is cached at `$XDG_CACHE_HOME/quickshell/term-llm-usage.json` and
contains no credentials or raw provider responses. The slim marker on each
progress bar shows the even-consumption pace that would reach the limit exactly
when its window resets.

System Help runs `term-llm ask --agent system-help --json --approval auto`
directly for each message and resumes the exact CLI session for follow-ups.
There is no HTTP server, web UI, port, or token. Install/update its public agent
before first use:

```sh
~/.config/hypr/system-help-setup
~/.config/hypr/shell-system-help
```

The popup starts blank and keeps its conversation when hidden. Its local
transcript/session pointer stays private in
`$XDG_STATE_HOME/system-help/conversation-cli.json`; term-llm owns the actual
session history in its normal session store. Old HTTP conversations are not
imported. Opening the popup does not invoke a model. Stop cancels the CLI process
group; exiting/restarting Quickshell cancels the active turn rather than leaving
a backend running. New clears the popup and starts a fresh session.

This direct-CLI trial uses Guardian-reviewed auto approval, never yolo. Native
CLI approval forms cannot be answered here and run without terminal access.
The agent asks follow-up/confirmation questions as ordinary chat messages rather
than using `ask_user`. JSONL exposes tool arguments/status, but not full tool
result bodies. `TERM_LLM_BIN` optionally selects a different binary;
`SYSTEM_HELP_CWD` overrides the default working directory (home).

Bridge regression tests (mock CLI, no provider calls):

```sh
PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover \
  -s ~/.config/hypr/quickshell -p 'test_system_help_bridge.py' -v
```
