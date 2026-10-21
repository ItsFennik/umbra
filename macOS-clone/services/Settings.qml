pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

// Settings changed from the Umbra Settings app, stored in $XDG_STATE_HOME/umbra/settings.json.
// Config seeds every value until the file exists.
Singleton {
    id: root

    readonly property bool showDock: value("showDock")
    readonly property int dockIconSize: value("dockIconSize")
    readonly property bool dockMagnification: value("dockMagnification")
    readonly property real dockMagnificationScale: value("dockMagnificationScale")
    readonly property bool dockAutoHide: value("dockAutoHide")
    readonly property bool dockAnimateLaunch: value("dockAnimateLaunch")
    readonly property bool dockShowIndicators: value("dockShowIndicators")
    readonly property bool dockShowRunning: value("dockShowRunning")

    readonly property var keys: ["showDock", "dockIconSize", "dockMagnification", "dockMagnificationScale", "dockAutoHide", "dockAnimateLaunch", "dockShowIndicators", "dockShowRunning"]

    // Whether the Settings window is open, and which page it shows; not persisted.
    property bool windowOpen: false
    property string page: "appearance"

    function value(key) {
        return file.loaded ? adapter[key] : Config[key];
    }

    function set(key, newValue) {
        if (!file.loaded) {
            for (const k of keys)
                adapter[k] = Config[k];
        }
        adapter[key] = newValue;
        file.loaded = true;
        file.writeAdapter();
    }

    function openPage(name) {
        page = name;
        windowOpen = true;
    }

    FileView {
        id: file

        property bool loaded: false

        path: (Quickshell.env("XDG_STATE_HOME") || Quickshell.env("HOME") + "/.local/state") + "/umbra/settings.json"
        atomicWrites: true
        printErrors: false
        onLoaded: loaded = true
        onLoadFailed: error => {
            if (error !== FileViewError.FileNotFound)
                console.warn("Umbra: cannot read settings:", FileViewError.toString(error));
        }

        // Defaults only matter for keys missing from an older file.
        JsonAdapter {
            id: adapter
            property bool showDock: Config.showDock
            property int dockIconSize: Config.dockIconSize
            property bool dockMagnification: Config.dockMagnification
            property real dockMagnificationScale: Config.dockMagnificationScale
            property bool dockAutoHide: Config.dockAutoHide
            property bool dockAnimateLaunch: Config.dockAnimateLaunch
            property bool dockShowIndicators: Config.dockShowIndicators
            property bool dockShowRunning: Config.dockShowRunning
        }
    }
}
