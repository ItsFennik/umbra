pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

// Current wallpaper and picker folder, stored in $XDG_STATE_HOME/umbra/wallpaper.json.
// Config seeds both on first run.
Singleton {
    id: root

    readonly property string path: file.loaded && adapter.path !== "" ? adapter.path : Config.wallpaper
    readonly property string directory: file.loaded && adapter.directory !== "" ? adapter.directory : Config.wallpaperDirectory

    function expand(p) {
        return p.startsWith("~/") ? Quickshell.env("HOME") + p.slice(1) : p;
    }

    function set(newPath) {
        adapter.path = expand(newPath);
        save();
    }

    function setDirectory(newDirectory) {
        adapter.directory = expand(newDirectory);
        save();
    }

    function save() {
        if (adapter.path === "")
            adapter.path = path;
        if (adapter.directory === "")
            adapter.directory = directory;
        file.loaded = true;
        file.writeAdapter();
    }

    FileView {
        id: file

        property bool loaded: false

        path: (Quickshell.env("XDG_STATE_HOME") || Quickshell.env("HOME") + "/.local/state") + "/umbra/wallpaper.json"
        atomicWrites: true
        printErrors: false
        onLoaded: loaded = true
        onLoadFailed: error => {
            if (error !== FileViewError.FileNotFound)
                console.warn("Umbra: cannot read wallpaper state:", FileViewError.toString(error));
        }

        JsonAdapter {
            id: adapter
            property string path: ""
            property string directory: ""
        }
    }
}
