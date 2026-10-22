pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

// Settings changed from the Umbra Settings app, stored in $XDG_STATE_HOME/umbra/settings.json.
// Config seeds every value until the file exists. Changes apply live: everything binds to these.
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

    readonly property int barHeight: value("barHeight")
    readonly property real barOpacity: value("barOpacity")
    readonly property var barLayout: value("barLayout")
    readonly property int barMediaSize: value("barMediaSize")
    readonly property int barMediaWidth: value("barMediaWidth")
    readonly property string barMediaText: value("barMediaText")

    readonly property string fontFamily: value("fontFamily")
    readonly property string fallbackFont: value("fallbackFont")
    readonly property string emojiFont: value("emojiFont")
    readonly property int fontSize: value("fontSize")
    readonly property int fontWeight: value("fontWeight")

    readonly property bool animations: value("animations")
    readonly property bool blur: value("blur")
    readonly property bool transparency: value("transparency")

    readonly property bool gtkMatugen: value("gtkMatugen")

    readonly property var keys: ["showDock", "dockIconSize", "dockMagnification", "dockMagnificationScale", "dockAutoHide", "dockAnimateLaunch", "dockShowIndicators", "dockShowRunning",
        "barHeight", "barOpacity", "barLayout", "barMediaSize", "barMediaWidth", "barMediaText",
        "fontFamily", "fallbackFont", "emojiFont", "fontSize", "fontWeight", "animations", "blur", "transparency", "gtkMatugen"]
    readonly property var fontKeys: ["fontFamily", "fallbackFont", "emojiFont", "fontSize", "fontWeight"]

    // Whether the Settings window is open, and which page it shows; not persisted.
    property bool windowOpen: false
    property string page: "appearance"
    // Desktop widget the Widgets page expands, e.g. after "Widget Settings…".
    property string widgetFocus: ""

    function value(key) {
        return file.loaded ? adapter[key] : Config[key];
    }

    function set(key, newValue) {
        setMany({ [key]: newValue });
    }

    // Applies several values with one write. Unknown keys are ignored.
    function setMany(values) {
        if (!file.loaded) {
            for (const k of keys)
                adapter[k] = Config[k];
        }
        for (const k in values) {
            if (keys.includes(k) && values[k] !== undefined && values[k] !== null)
                adapter[k] = values[k];
        }
        file.loaded = true;
        file.writeAdapter();
    }

    function reset(resetKeys) {
        const values = {};
        for (const k of resetKeys ?? keys)
            values[k] = Config[k];
        setMany(values);
    }

    function snapshot() {
        const values = {};
        for (const k of keys)
            values[k] = value(k);
        return values;
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
            property int barHeight: Config.barHeight
            property real barOpacity: Config.barOpacity
            property var barLayout: Config.barLayout
            property int barMediaSize: Config.barMediaSize
            property int barMediaWidth: Config.barMediaWidth
            property string barMediaText: Config.barMediaText
            property string fontFamily: Config.fontFamily
            property string fallbackFont: Config.fallbackFont
            property string emojiFont: Config.emojiFont
            property int fontSize: Config.fontSize
            property int fontWeight: Config.fontWeight
            property bool animations: Config.animations
            property bool blur: Config.blur
            property bool transparency: Config.transparency
            property bool gtkMatugen: Config.gtkMatugen
        }
    }
}
