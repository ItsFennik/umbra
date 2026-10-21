# Umbra

A macOS-inspired desktop shell for Wayland, built on Quickshell. The compositor stays
in charge of window management; Umbra talks to it through standard protocols
(foreign-toplevel, ext-workspace, layer-shell, screencopy) and only uses
compositor-specific adapters where those protocols fall short.

## Run

```sh
qs -p ~/Projects/macOS-clone
```

## Requirements

- Quickshell 0.3+
- A compositor with `wlr-layer-shell`
- Optional, each feature hides itself when missing:
  - PipeWire: volume and output selection
  - NetworkManager: Wi-Fi and Ethernet
  - BlueZ: Bluetooth
  - UPower: battery
  - `brightnessctl` plus a backlight device: display brightness
  - `gsettings`: dark/light mode
  - `matugen`: wallpaper-matched colors (toggle in Control Center or `ipc call colors toggle`)
  - `ext-workspace-v1`: workspaces
  - window capture support: overview thumbnails (app icons otherwise)

## Keybinds

Umbra exposes IPC targets; bind them in your compositor. Any command works:

```sh
qs -p ~/Projects/macOS-clone ipc call <target> toggle
```

Hyprland, classic `hyprland.conf`:

```
bind = SUPER, D,   exec, qs -p ~/Projects/macOS-clone ipc call launcher toggle
bind = SUPER, TAB, exec, qs -p ~/Projects/macOS-clone ipc call overview toggle
bind = SUPER, N,   exec, qs -p ~/Projects/macOS-clone ipc call notifications toggle
bind = SUPER, C,   exec, qs -p ~/Projects/macOS-clone ipc call controlcenter toggle
```

Hyprland, Lua `hyprland.lua`:

```lua
local umbra = "qs -p ~/Projects/macOS-clone ipc call "
hl.bind("SUPER + D",   hl.dsp.exec_cmd(umbra .. "launcher toggle"))
hl.bind("SUPER + TAB", hl.dsp.exec_cmd(umbra .. "overview toggle"))
hl.bind("SUPER + N",   hl.dsp.exec_cmd(umbra .. "notifications toggle"))
hl.bind("SUPER + C",   hl.dsp.exec_cmd(umbra .. "controlcenter toggle"))
```

Each target also has `open` and `close`; `notifications` has `clear`.
`settings toggle` opens Umbra Settings (also in the logo menu and Control Center); `settings page <name>`
opens a page: `user`, `appearance`, `wallpaper`, `dock`, `icons`, `cursors`. Choosing a profile picture uses `zenity`.

## Layout

- `config/`: theme, settings, and which panel is open
- `services/`: system and compositor integration, no UI
  - `services/adapters/`: compositor-specific extras, loaded only when detected
- `components/`: shared widgets (icons, slider, switch, popup surface)
- `modules/`: bar, dock, launcher, controlcenter, notifications, overview

Dock pins are stored in `$XDG_STATE_HOME/umbra/dock.json`, Umbra Settings in `settings.json` next to it.

## Compositor support

Umbra assumes only standard protocols. Two notes:

- Overview filters windows by workspace only through an adapter (Hyprland today).
  Elsewhere it shows all windows and says so.
- Only one notification server can own the bus name. Stop any other notification
  daemon or shell to receive notifications in Umbra.
