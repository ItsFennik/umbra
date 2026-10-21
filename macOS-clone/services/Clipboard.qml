pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Clipboard history through cliphist, and copying through wl-copy. Either may be missing;
// `available` and `canCopy` say what works. History needs `wl-paste --watch cliphist store` running.
Singleton {
    id: root

    property bool available: false
    property bool canCopy: false
    property bool loading: false
    // [{ id, text, line, binary }], newest first; line is cliphist's raw "id\tpreview".
    property var entries: []

    readonly property int limit: 200

    function refresh() {
        if (!available)
            return;
        loading = true;
        lister.running = false;
        lister.running = true;
    }

    function copyText(text) {
        if (!canCopy) {
            console.warn("Umbra: cannot copy, wl-copy is not installed");
            return false;
        }
        run(["wl-copy", "--", text]);
        return true;
    }

    function copyEntry(entry) {
        run(["sh", "-c", "printf '%s' \"$1\" | cliphist decode | wl-copy", "sh", entry.line]);
    }

    function remove(entry) {
        entries = entries.filter(e => e.id !== entry.id);
        run(["sh", "-c", "printf '%s' \"$1\" | cliphist delete", "sh", entry.line]);
    }

    function wipe() {
        entries = [];
        run(["cliphist", "wipe"]);
    }

    function run(command) {
        const proc = runner.createObject(root, { command: command });
        proc.running = true;
    }

    Component {
        id: runner

        Process {
            id: proc
            onExited: code => {
                if (code !== 0)
                    console.warn("Umbra: clipboard command failed with " + code + ":", proc.command.join(" "));
                proc.destroy();
            }
        }
    }

    Process {
        running: true
        command: ["sh", "-c", "command -v cliphist >/dev/null && echo cliphist; command -v wl-copy >/dev/null && echo wl-copy"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.canCopy = text.includes("wl-copy");
                root.available = text.includes("cliphist") && root.canCopy;
            }
        }
    }

    Process {
        id: lister
        command: ["cliphist", "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                const result = [];
                for (const line of text.split("\n")) {
                    const tab = line.indexOf("\t");
                    if (tab < 0)
                        continue;
                    const preview = line.slice(tab + 1);
                    result.push({ id: line.slice(0, tab), text: preview, line: line, binary: /^\[\[ binary data/.test(preview) });
                    if (result.length >= root.limit)
                        break;
                }
                root.entries = result;
                root.loading = false;
            }
        }
        onExited: code => {
            if (code !== 0) {
                console.warn("Umbra: cliphist list failed with", code);
                root.loading = false;
            }
        }
    }
}
