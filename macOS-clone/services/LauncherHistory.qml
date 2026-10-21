pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// What the launcher remembers, in $XDG_STATE_HOME/umbra/launcher.json:
//   queries  recent searches that led somewhere, newest first
//   commands recent "> command" runs
//   emoji    recently copied emoji
//   apps     launch counts by desktop ID, to rank frequent apps higher
Singleton {
    id: root

    readonly property var queries: list(adapter.queries)
    readonly property var commands: list(adapter.commands)
    readonly property var emoji: list(adapter.emoji)
    readonly property var apps: adapter.apps ?? {}

    function list(value) {
        try {
            return Array.from(value ?? []).filter(v => typeof v === "string");
        } catch (e) {
            return [];
        }
    }

    function remember(values, value, max) {
        return [value].concat(values.filter(v => v !== value)).slice(0, max);
    }

    function recordQuery(text) {
        const t = text.trim();
        if (t === "")
            return;
        adapter.queries = remember(queries, t, 20);
        save();
    }

    function recordCommand(command) {
        adapter.commands = remember(commands, command.trim(), 30);
        save();
    }

    function recordEmoji(glyph) {
        adapter.emoji = remember(emoji, glyph, 24);
        save();
    }

    function recordApp(id) {
        adapter.apps = Object.assign({}, apps, { [id]: (apps[id] ?? 0) + 1 });
        save();
    }

    function removeQuery(text) {
        adapter.queries = queries.filter(q => q !== text);
        save();
    }

    function removeCommand(command) {
        adapter.commands = commands.filter(c => c !== command);
        save();
    }

    function clear() {
        adapter.queries = [];
        adapter.commands = [];
        adapter.emoji = [];
        save();
    }

    function save() {
        file.writeAdapter();
    }

    FileView {
        id: file

        path: (Quickshell.env("XDG_STATE_HOME") || Quickshell.env("HOME") + "/.local/state") + "/umbra/launcher.json"
        atomicWrites: true
        printErrors: false
        onLoadFailed: error => {
            if (error !== FileViewError.FileNotFound)
                console.warn("Umbra: cannot read launcher history:", FileViewError.toString(error));
        }

        JsonAdapter {
            id: adapter
            property var queries: []
            property var commands: []
            property var emoji: []
            property var apps: ({})
        }
    }
}
