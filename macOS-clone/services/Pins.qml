pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

// Persistent, user-ordered list of pinned desktop IDs.
// Stored in $XDG_STATE_HOME/umbra/dock.json; Config.pinnedApps seeds it on first run.
Singleton {
    id: root

    readonly property list<string> pinned: file.loaded ? adapter.pinned : Config.pinnedApps

    function isPinned(key) {
        return pinned.includes(key);
    }

    // Pins `key` before `beforeKey`, or last when it is null (moving it if already pinned).
    function pin(key, beforeKey) {
        const list = pinned.filter(k => k !== key);
        const index = list.indexOf(beforeKey);
        list.splice(index < 0 ? list.length : index, 0, key);
        save(list);
    }

    function unpin(key) {
        save(pinned.filter(k => k !== key));
    }

    function save(list) {
        adapter.pinned = list;
        file.loaded = true;
        file.writeAdapter();
    }

    FileView {
        id: file

        property bool loaded: false

        path: (Quickshell.env("XDG_STATE_HOME") || Quickshell.env("HOME") + "/.local/state") + "/umbra/dock.json"
        atomicWrites: true
        printErrors: false
        onLoaded: loaded = true
        onLoadFailed: error => {
            if (error !== FileViewError.FileNotFound)
                console.warn("Umbra: cannot read dock pins:", FileViewError.toString(error));
        }

        JsonAdapter {
            id: adapter
            property list<string> pinned: []
        }
    }
}
