pragma Singleton
import QtQuick
import Quickshell

// User-facing settings. Desktop IDs are .desktop file names without the extension.
Singleton {
    readonly property list<string> pinnedApps: [
        "org.gnome.Nautilus",
        "librewolf",
        "foot",
        "vesktop",
        "steam"
    ]

    // Initial wallpaper and the folder the picker browses; changes made in Umbra are saved separately.
    readonly property string wallpaper: Quickshell.env("HOME") + "/Documents/kemuri-hokkaido-14.png"
    readonly property string wallpaperDirectory: Quickshell.env("HOME") + "/Pictures/Wallpapers"

    // Default for "Match Wallpaper Colors" (needs matugen); toggling it in Umbra is saved separately.
    readonly property bool matugenColors: false
    // matugen --type: scheme-tonal-spot, scheme-content, scheme-vibrant, scheme-expressive, ...
    readonly property string matugenScheme: "scheme-tonal-spot"

    // Defaults for the Umbra Settings app; changes made there are saved separately.
    readonly property bool showDock: true
    readonly property int dockIconSize: 48
    readonly property bool dockMagnification: true
    readonly property real dockMagnificationScale: 1.35
    readonly property bool dockAutoHide: false
    readonly property bool dockAnimateLaunch: true
    readonly property bool dockShowIndicators: true
    readonly property bool dockShowRunning: true

    // Preferred UI fonts, first installed one wins, while Umbra Settings leaves the font on Automatic.
    readonly property list<string> fontFamilies: ["SF Pro Text", "Inter", "Geist", "Noto Sans", "Cantarell"]
    readonly property list<string> emojiFamilies: ["Apple Color Emoji", "Noto Color Emoji", "Twemoji", "JoyPixels", "Segoe UI Emoji"]

    // Defaults for Umbra's own fonts (never the system's). "" means Automatic.
    readonly property string fontFamily: ""
    readonly property string fallbackFont: ""
    readonly property string emojiFont: ""
    readonly property int fontSize: 13
    readonly property int fontWeight: 400

    // Defaults for the performance switches; off falls back to cheaper drawing.
    readonly property bool animations: true
    readonly property bool blur: true
    readonly property bool transparency: true

    // Terminal for "> command" in the launcher when $TERMINAL is unset; the first installed one wins.
    readonly property list<string> terminals: ["foot", "kitty", "alacritty", "wezterm", "ghostty", "konsole", "gnome-terminal", "xterm"]
}
