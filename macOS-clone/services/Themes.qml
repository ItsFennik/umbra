pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Installed icon and cursor themes, and applying them system-wide:
//   icons   -> gsettings, qt5ct/qt6ct, and Umbra's IconTheme pragma (needs a restart)
//   cursors -> gsettings, hyprctl setcursor, and the XCursor "default" theme
Singleton {
    id: root

    property var iconThemes: []
    property var cursorThemes: []
    // A few app icons from each icon theme, for previews: { theme: [paths] }.
    property var iconSamples: ({})
    property string iconTheme: ""
    property string cursorTheme: ""
    property int cursorSize: 24

    readonly property string home: Quickshell.env("HOME")
    readonly property string dataHome: Quickshell.env("XDG_DATA_HOME") || home + "/.local/share"
    readonly property string configHome: Quickshell.env("XDG_CONFIG_HOME") || home + "/.config"

    function refresh() {
        scan.running = false;
        scan.running = true;
    }

    function setIconTheme(name) {
        iconTheme = name;
        const shell = Quickshell.shellDir + "/shell.qml";
        Quickshell.execDetached(["sh", "-c", `
            gsettings set org.gnome.desktop.interface icon-theme "$1"
            for f in "$2/qt6ct/qt6ct.conf" "$2/qt5ct/qt5ct.conf"; do
                [ -f "$f" ] && sed -i "s|^icon_theme=.*|icon_theme=$1|" "$f"
            done
            sed -i "s|^//@ pragma IconTheme .*|//@ pragma IconTheme $1|" "$3"
            sleep 0.3
            qs kill -p "$4"
            qs -p "$4" -d`, "sh", name, configHome, shell, Quickshell.shellDir]);
    }

    function setCursor(name, size) {
        cursorTheme = name;
        cursorSize = size;
        Quickshell.execDetached(["sh", "-c", `
            gsettings set org.gnome.desktop.interface cursor-theme "$1"
            gsettings set org.gnome.desktop.interface cursor-size "$2"
            hyprctl setcursor "$1" "$2" >/dev/null 2>&1
            mkdir -p "$3/icons/default"
            printf '[Icon Theme]\\nName=Default\\nComment=Default Cursor Theme\\nInherits=%s\\n' "$1" > "$3/icons/default/index.theme"`,
            "sh", name, String(size), dataHome]);
    }

    Component.onCompleted: refresh()

    // Prints "icon <name>" / "cursor <name>" for every theme, then "current <icons> <cursor> <size>".
    Process {
        id: scan
        command: ["sh", "-c", `
            for d in "$1/icons"/* "$2/.icons"/* /usr/share/icons/*; do
                [ -f "$d/index.theme" ] || continue
                n=$(basename "$d")
                case "$n" in default|hicolor|locolor) continue ;; esac
                [ -d "$d/cursors" ] && echo "cursor $n"
                ls "$d" | grep -qvE '^(cursors|index\\.theme|cursor\\.theme)$' && echo "icon $n"
            done
            icons=$(gsettings get org.gnome.desktop.interface icon-theme 2>/dev/null | tr -d "'")
            cursor=$(gsettings get org.gnome.desktop.interface cursor-theme 2>/dev/null | tr -d "'")
            [ "$cursor" = default ] || [ -z "$cursor" ] && cursor=$(sed -n 's/^Inherits=//p' "$1/icons/default/index.theme" "$2/.icons/default/index.theme" 2>/dev/null | head -n1)
            size=$(gsettings get org.gnome.desktop.interface cursor-size 2>/dev/null)
            echo "current \${icons:-none} \${cursor:-none} \${size:-24}"`, "sh", root.dataHome, root.home]
        stdout: StdioCollector {
            onStreamFinished: {
                const icons = [], cursors = [];
                for (const line of text.trim().split("\n")) {
                    const [kind, ...rest] = line.split(" ");
                    if (kind === "icon" && !icons.includes(rest[0]))
                        icons.push(rest[0]);
                    else if (kind === "cursor" && !cursors.includes(rest[0]))
                        cursors.push(rest[0]);
                    else if (kind === "current") {
                        root.iconTheme = rest[0] === "none" ? "" : rest[0];
                        root.cursorTheme = rest[1] === "none" ? "" : rest[1];
                        root.cursorSize = parseInt(rest[2]) || 24;
                    }
                }
                root.iconThemes = icons.sort((a, b) => a.localeCompare(b));
                root.cursorThemes = cursors.sort((a, b) => a.localeCompare(b));
                samples.running = true;
            }
        }
    }

    // Prints "<theme> <path>" for preview icons; sizes are preferred scalable, then large.
    Process {
        id: samples

        readonly property var names: ["folder", "utilities-terminal", "web-browser", "preferences-system"]

        command: ["sh", "-c", `
            for d in "$1/icons"/* "$2/.icons"/* /usr/share/icons/*; do
                [ -f "$d/index.theme" ] || continue
                n=$(basename "$d")
                find -L "$d" \\( -name 'folder.svg' -o -name 'utilities-terminal.svg' -o -name 'web-browser.svg' -o -name 'preferences-system.svg' \
                    -o -name 'folder.png' -o -name 'utilities-terminal.png' -o -name 'web-browser.png' -o -name 'preferences-system.png' \\) \
                    -not -path '*symbolic*' 2>/dev/null | sed "s|^|$n |"
            done`, "sh", root.dataHome, root.home]
        stdout: StdioCollector {
            onStreamFinished: {
                const rank = path => path.includes("scalable") ? 0 : /\b(256|128|96|64|48)\b/.test(path) ? 1 : 2;
                const best = {};
                for (const line of text.trim().split("\n")) {
                    const space = line.indexOf(" ");
                    const theme = line.slice(0, space), path = line.slice(space + 1);
                    const name = path.split("/").pop().replace(/\.(svg|png)$/, "");
                    best[theme] = best[theme] ?? {};
                    const current = best[theme][name];
                    if (!current || rank(path) < rank(current))
                        best[theme][name] = path;
                }
                const result = {};
                for (const theme in best)
                    result[theme] = samples.names.map(n => best[theme][n]).filter(p => p);
                root.iconSamples = result;
            }
        }
    }
}
