pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// The current user's display name and picture. The picture lives in ~/.face, which
// login managers read; AccountsService is updated too when it allows it.
Singleton {
    id: root

    readonly property string login: Quickshell.env("USER")
    property string name: login
    readonly property string facePath: Quickshell.env("HOME") + "/.face"
    property bool hasFace: false
    // Bumped after each change so Image reloads the same path.
    property int revision: 0
    readonly property bool canPick: picker.available

    function setPicture(path) {
        apply.command = ["sh", "-c", `
            cp -f "$1" "$2" || exit 1
            busctl call org.freedesktop.Accounts "/org/freedesktop/Accounts/User$(id -u)" \\
                org.freedesktop.Accounts.User SetIconFile s "$2" >/dev/null 2>&1
            exit 0`, "sh", path, facePath];
        apply.running = true;
    }

    function removePicture() {
        apply.command = ["rm", "-f", facePath];
        apply.running = true;
    }

    function pickPicture() {
        picker.running = true;
    }

    Process {
        id: apply
        onExited: code => {
            if (code !== 0)
                console.warn("Umbra: cannot change the user picture");
            check.running = true;
        }
    }

    Process {
        id: check
        running: true
        command: ["test", "-f", root.facePath]
        onExited: code => {
            root.hasFace = code === 0;
            root.revision++;
        }
    }

    Process {
        running: true
        command: ["sh", "-c", "getent passwd \"$USER\" | cut -d: -f5 | cut -d, -f1"]
        stdout: StdioCollector {
            onStreamFinished: if (text.trim() !== "") root.name = text.trim()
        }
    }

    Process {
        id: picker

        property bool available: false

        command: ["zenity", "--file-selection", "--title=Choose a Picture", "--file-filter=Images | *.png *.jpg *.jpeg *.webp *.PNG *.JPG *.JPEG *.WEBP"]
        stdout: StdioCollector {
            onStreamFinished: if (text.trim() !== "") root.setPicture(text.trim())
        }
        Component.onCompleted: probe.running = true
    }

    Process {
        id: probe
        command: ["sh", "-c", "command -v zenity"]
        onExited: code => picker.available = code === 0
    }
}
