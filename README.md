# Umbra

A macOS-inspired Wayland desktop shell built with Quickshell and QML.

Umbra is a personal project exploring macOS-inspired UI design on Linux. It's experimental, mostly vibe-coded (roughly 80% AI-assisted), and not production-ready.

I develop Umbra in my own time, with no guarantees of stability, support, or regular updates. It's a project I intend to keep developing for my own use.

## Tech Stack

- [Quickshell](https://quickshell.org/)
- Qt 6
- QML
- JavaScript
- Wayland

## Requirements

- Linux with Wayland
- [Quickshell](https://quickshell.org/)
- A compatible Wayland compositor

## Installation

```bash
git clone https://github.com/ItsFennik/umbra.git
cd umbra
```

Launch the configuration:

```bash
qs -p ~/.config/quickshell/umbra
```

Alternatively, launch directly from the cloned repository if `macOS-clone` contains the Quickshell configuration:

```bash
qs -p "$PWD/macOS-clone"
```

## Autostart

Create `~/.config/systemd/user/umbra.service`:

```ini
[Unit]
Description=Umbra Desktop Shell
After=graphical-session.target

[Service]
ExecStart=/usr/bin/qs -p %h/.config/quickshell/umbra
Restart=on-failure
RestartSec=2

[Install]
WantedBy=graphical-session.target
```

Enable it:

```bash
systemctl --user daemon-reload
systemctl --user enable --now umbra.service
```

View logs:

```bash
journalctl --user -u umbra.service -b
```

If `qs` is not located at `/usr/bin/qs`, replace that path with the output of `command -v qs`.

## Keybindings

Keyboard shortcuts depend on the compositor and the actions implemented by Umbra. No default bindings are guaranteed.

## Roadmap

- [ ] macOS-inspired top bar and dock
- [ ] Spotlight-style launcher
- [ ] Notification center
- [ ] Quick settings
- [ ] Audio and media controls
- [ ] Theme and wallpaper customization

## Contributing

Contributions and suggestions are welcome. Umbra is experimental, and updates are not guaranteed.

## License

See [LICENSE](LICENSE).
