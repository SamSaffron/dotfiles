# Quickshell Hyprland trial

A full-shell A/B test against the existing Waybar + Fuzzel + Dunst setup. The
colors, typography, modules, and bottom placement intentionally remain close to
the current bar; the difference is the integrated motion and interaction:

- animated Hyprland workspaces and active-window title
- system metrics, update count, Sydney weather, PipeWire volume, and tray
- cached ChatGPT, Claude, OpenCode Go, and Cursor subscription usage
- searchable application launcher (`Super+D`)
- control center with quick actions, volume, media, and metrics (`Super+C`)
- native notification popups and do-not-disturb mode
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
qs -p ~/.config/hypr/quickshell/shell.qml ipc call shell toggleControlCenter
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
