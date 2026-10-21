# Umbra

A macOS-inspired Wayland desktop shell built with Quickshell and QML.

Umbra is a personal project focused on experimenting with desktop UI design on Linux, taking inspiration from macOS while keeping things customizable and suited to a Wayland environment.

Most of this project is vibe-coded, with roughly 80% of the code written with AI assistance. It's an experiment, not a production-ready desktop shell, so expect bugs, unfinished features, and questionable implementation choices.

Development happens in my own time, with no promises of regular updates, long-term support, or stability. I'm building this because I want to, and I'll take it wherever I feel like going.

Realistically, Umbra is something I intend to use for as long as I'm on Linux, so despite the experimental nature of the project, it's something I plan to keep developing for my own use.

If you like macOS-inspired Linux desktops, feel free to stick around, try it out, or contribute.

If you have an issue with AI-assisted development, that's fine, but this is my personal project and I'm comfortable with how I'm building it. I'm not here to debate it or convince anyone otherwise.

## Tech Stack

- [Quickshell](https://quickshell.org/)
- Qt 6
- QML
- JavaScript
- Wayland

## Requirements

- A Linux distribution running Wayland
- [Quickshell](https://quickshell.org/) installed
- Qt 6 and the required Qt modules for your Quickshell build
- A compatible Wayland compositor

## Installation

Clone the repository:

```bash
git clone https://github.com/ItsFennik/umbra.git
cd umbra
```

The current project files are located in the `macOS-clone` directory.

Make sure the configuration directory is placed in your Quickshell configuration directory:

```text
~/.config/quickshell/umbra/
```

The directory should contain the shell's entry-point QML file and any other required project files.

## Usage

Launch Umbra with:

```bash
qs -p ~/.config/quickshell/umbra
```

If you cloned the repository and are running it directly from the project directory, use the actual path to the configuration instead:

```bash
qs -p "$PWD/macOS-clone"
```

Use whichever command matches the location of your Quickshell configuration.

To stop the shell, terminate the Quickshell process running Umbra.

## Autostart

To launch Umbra automatically when you log in, create a systemd user service.

Create the service directory:

```bash
mkdir -p ~/.config/systemd/user
```

Create `~/.config/systemd/user/umbra.service`:

```ini
[Unit]
Description=Umbra Wayland Desktop Shell
PartOf=graphical-session.target
After=graphical-session.target

[Service]
Type=simple
ExecStart=/usr/bin/qs -p %h/.config/quickshell/umbra
Restart=on-failure
RestartSec=2

[Install]
WantedBy=graphical-session.target
```

If `qs` is installed somewhere other than `/usr/bin/qs`, replace the executable path with the output of:

```bash
command -v qs
```

Enable the service:

```bash
systemctl --user daemon-reload
systemctl --user enable --now umbra.service
```

Check its status:

```bash
systemctl --user status umbra.service
```

View logs if something goes wrong:

```bash
journalctl --user -u umbra.service -b

## Keybindings

Umbra exposes shell actions that can be bound to keyboard shortcuts through your Wayland compositor.

| Action | Suggested shortcut |
|---|---|
| Open Spotlight launcher | `Super + Space` |
| Toggle application dock | `Super + D` |
| Open notification center | `Super + N` |
| Open quick settings | `Super + A` |
| Close active window | `Super + Q` |

These shortcuts are suggestions. They require the corresponding shell components and compositor bindings to be implemented.
```

If your compositor does not activate `graphical-session.target`, you may need to start the service through your compositor's autostart configuration instead.

## Roadmap

The following are ideas for the project, not guarantees:

- [ ] macOS-inspired top bar and dock
- [ ] Application launcher
- [ ] Notification center
- [ ] Quick settings and system controls
- [ ] Audio and media controls
- [ ] Theme and wallpaper customization
- [ ] Compositor integrations

## Contributing

Contributions, suggestions, and bug reports are welcome. Keep in mind that Umbra is experimental and is developed in my own time, so responses and updates are not guaranteed.

## License

See [LICENSE](LICENSE) for the applicable license.
