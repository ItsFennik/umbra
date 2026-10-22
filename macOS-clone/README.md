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
  - `cava`: audio spectrum in the Now Playing and Visualizer widgets
  - `wl-clipboard`: copying from the launcher (calculator results, emoji, clipboard history)
  - `cliphist`: clipboard history in the launcher (`c>`), with `wl-paste --watch cliphist store` running
  - a terminal for `> command` in the launcher: `$TERMINAL`, else foot, kitty, alacritty, …
  - `matugen`: wallpaper-matched colors (toggle in Control Center or `ipc call colors toggle`)
  - `mpvpaper`: live (video) wallpapers; `ffmpegthumbnailer` or `ffmpeg` for their thumbnails
  - PAM: the lock screen checks passwords with the `login` service
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
opens a page: `user`, `appearance`, `fonts`, `wallpaper`, `live`, `menubar`, `dock`, `widgets`, `profiles`, `performance`, `themes`, `icons`, `cursors`. Choosing a profile picture uses `zenity`.
`power toggle` opens the power menu (arrow keys and Enter, or the hinted letter: L, S, R, U, O); `power restart`, `shutdown` and `logout` ask first and
count down from 60 seconds, `power sleep` and `lock` act at once.
`media toggle` opens the Now Playing popout; `media playPause`, `next` and `previous` control the current player.

## Lock screen

Umbra locks with `ext-session-lock` and draws the Orbital clockwork skin on every screen: minute and
second dials orbit the hour, and unlocking winds them up until they burst. Passwords go through PAM.
It locks from the logo menu, the power menu, `ipc call lock lock`, or logind's Lock signal, so
`loginctl lock-session` and idle daemons such as hypridle (`lock_cmd = loginctl lock-session`) work
without a separate locker.

## Menu bar and Now Playing

Settings > Menu Bar arranges the bar by drag and drop: drag items between the Left, Center and
Right zones, or into Available to hide them (Playback Controls start there). The same page sets the
bar's height and background opacity. While a player is open the bar shows its track, and it stays
there while paused; its size, text width and text (title and artist, title, or artwork only) are
set there too. Click the track for the Now Playing popout, centred under it: artwork,
album, seekable progress, cava spectrum, player volume and a switcher when several players are
open. Scroll over the track to skip.

## Wallpapers

Settings > Wallpaper picks a still image from `~/Pictures/Wallpapers`. Settings > Live Wallpaper
plays a video from `~/Videos/Wallpapers` (folder editable there) behind the desktop with `mpvpaper`,
muted, looping and paused while covered. Wallpaper colors then come from a frame of the video.
Choosing a still image turns the live wallpaper off. Both are remembered in
`$XDG_STATE_HOME/umbra/wallpaper.json` and saved in profiles.

```sh
qs -p ~/Projects/macOS-clone ipc call wallpaper live ~/Videos/Wallpapers/rain.mp4   # also: liveOff, liveFolder <dir>
```

## Launcher

Type to search apps (frequently launched ones rank higher). Arithmetic such as `2*(3+4)^2` or
`sqrt(2)` shows its result; Enter copies it. A prefix switches mode, shown as a chip:

| Prefix | Mode |
| --- | --- |
| `e>` | Emoji search; Enter copies the emoji |
| `c>` | Clipboard history from cliphist; Enter copies, Shift+Delete removes |
| `>` | Shell command; Enter runs it in a terminal, Shift+Enter in the background |
| `=` | Calculator, showing why an expression does not parse |

With an empty field it lists recent searches. Keys: ↑/↓, Ctrl+P/N, Tab/Shift+Tab and Page Up/Down
select; Ctrl+1–9 picks a visible row; Esc clears the field, then leaves the mode, then closes;
Backspace in an empty field leaves the mode. The footer shows the keys for the selected row.
History is kept in `$XDG_STATE_HOME/umbra/launcher.json`.

```sh
qs -p ~/Projects/macOS-clone ipc call launcher emoji        # also: clipboard, command, search <text>
```

## Desktop widgets

Right-click the wallpaper to add a widget, or use Settings > Widgets. Built in: Now Playing (media
controls), Visualizer, Clock, Calendar, Battery, Network Speed, CPU & Memory and Workspaces, all from
live system data (MPRIS, cava, UPower, `/proc`, ext-workspace). Drag a widget to move it, drag its
corner to resize it (Shift keeps its shape), right-click it to restack, reset or remove it, or for
its settings. Settings > Widgets lists them in stacking order; drag the grip to restack. Widgets sit
between the wallpaper and windows, and are stored in `$XDG_STATE_HOME/umbra/widgets.json`. cava only
runs while a visible spectrum exists and something is playing; `/proc` is only read while a system
widget is on screen.

```sh
qs -p ~/Projects/macOS-clone ipc call widgets add calendar  # see `widgets types`
qs -p ~/Projects/macOS-clone ipc call widgets clear
```

### Writing a widget

Each folder in `modules/widgets/` with a `manifest.json` and a `Widget.qml` is a widget type; it
appears in the menus and in Settings without registering anywhere (`widgets reload` rescans).

```json
{
    "name": "Uptime", "description": "Time since boot", "icon": "clock",
    "width": 200, "height": 90, "minWidth": 140, "minHeight": 70, "glass": true,
    "settings": [
        { "key": "seconds", "label": "Show seconds", "type": "bool", "default": false },
        { "key": "style", "label": "Style", "type": "choice", "default": "short",
          "options": [{ "value": "short", "text": "Short" }, { "value": "long", "text": "Long" }] }
    ]
}
```

`Widget.qml` has a `WidgetBase` root (`import qs.modules.widgets`) and reads its settings from
`options`; setting types are `bool`, `range` (`from`, `to`, `step`, `unit`), `choice` and `text`,
and Settings builds their controls. `WidgetCard` draws the standard glass card and `Sparkline` a
small graph. See `services/Widgets.qml` for every manifest field.

## Fonts, profiles and performance

- **Fonts** sets Umbra's interface font, size and weight, plus a fallback font (used when the chosen
  font is not installed) and the emoji font. Hovering a font previews it. Only Umbra changes;
  GTK, Qt and fontconfig settings are left alone.
- **Profiles** save the current setup under a name: every Umbra setting, light or dark mode,
  wallpaper colors, wallpaper, desktop widgets and Dock pins (not icon or cursor themes, which are
  system-wide). Stored in `$XDG_STATE_HOME/umbra/profiles.json`.
- **Performance** toggles animations, blur and transparency independently. Without blur, surfaces
  use denser tints; without transparency, they are solid.

Everything applies live. From a keybind or script:

```sh
qs -p ~/Projects/macOS-clone ipc call settings set animations false   # any key in services/Settings.qml
qs -p ~/Projects/macOS-clone ipc call profiles apply Evening           # also: list, save <name>, remove <name>
```

## Layout

- `config/`: theme, settings, and which panel is open
- `services/`: system and compositor integration, no UI
  - `services/adapters/`: compositor-specific extras, loaded only when detected
- `components/`: shared widgets (icons, slider, switch, popup surface)
- `modules/`: bar, dock, launcher, controlcenter, media, notifications, overview, lock, power, menu, settings, wallpaper, widgets

Dock pins are stored in `$XDG_STATE_HOME/umbra/dock.json`, Umbra Settings in `settings.json` next to it.

## Compositor support

Umbra assumes only standard protocols. Two notes:

- Overview filters windows by workspace only through an adapter (Hyprland today).
  Elsewhere it shows all windows and says so.
- Only one notification server can own the bus name. Stop any other notification
  daemon or shell to receive notifications in Umbra.

## Credits

- Credits to **Ryoku**: the lock screen is the Orbital skin Ryoku brought over from
  [qylock](https://github.com/Darkkal44/qylock) by Darkkal44 (GPL-3.0).
