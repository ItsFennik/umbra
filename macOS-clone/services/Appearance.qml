pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Follows the freedesktop color-scheme preference via gsettings.
// Without gsettings, Umbra stays dark and reports the preference as undetected.
Singleton {
    id: root

    property bool dark: true
    property bool detected: false

    function setDark(on) {
        setter.command = ["gsettings", "set", "org.gnome.desktop.interface", "color-scheme", on ? "prefer-dark" : "prefer-light"];
        setter.running = true;
    }

    function apply(value) {
        root.detected = true;
        root.dark = value.includes("prefer-dark");
    }

    Process {
        id: setter
    }

    Process {
        running: true
        command: ["gsettings", "get", "org.gnome.desktop.interface", "color-scheme"]
        stdout: StdioCollector {
            onStreamFinished: if (text.trim() !== "") root.apply(text)
        }
    }

    Process {
        running: true
        command: ["gsettings", "monitor", "org.gnome.desktop.interface", "color-scheme"]
        stdout: SplitParser {
            onRead: line => root.apply(line)
        }
    }
}
