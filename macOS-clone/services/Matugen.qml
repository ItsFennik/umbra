pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

// Material You colors generated from the current wallpaper by matugen.
// The toggle is stored in $XDG_STATE_HOME/umbra/colors.json; Config seeds it on first run.
// Runs matugen with --dry-run, so it never touches the user's matugen templates.
Singleton {
    id: root

    readonly property bool enabled: file.loaded ? adapter.matugen : Config.matugenColors
    property bool available: false
    // Scheme for the current mode, keyed by matugen role (primary, surface, on_surface, ...).
    readonly property var colors: Appearance.dark ? scheme.dark : scheme.light
    readonly property bool active: enabled && available && colors.primary !== undefined
    // The palette is also generated for GTK apps (GtkTheme) while Umbra's own colors stay off.
    readonly property bool wanted: enabled || Settings.gtkMatugen

    property var scheme: ({ dark: {}, light: {} })

    function setEnabled(on) {
        adapter.matugen = on;
        file.loaded = true;
        file.writeAdapter();
    }

    function generate() {
        if (!wanted || !available || Wallpaper.colorSource === "")
            return;
        generator.running = false;
        generator.command = ["matugen", "image", Wallpaper.colorSource, "--dry-run", "--json", "hex", "--source-color-index", "0", "--type", Config.matugenScheme, "-q"];
        generator.running = true;
    }

    function parse(text) {
        let data;
        try {
            data = JSON.parse(text);
        } catch (e) {
            console.warn("Umbra: cannot parse matugen output:", e);
            return;
        }
        const dark = {}, light = {};
        for (const role in data.colors) {
            dark[role] = data.colors[role].dark.color;
            light[role] = data.colors[role].light.color;
        }
        scheme = { dark, light };
    }

    onWantedChanged: generate()
    onAvailableChanged: generate()

    Connections {
        target: Wallpaper
        function onColorSourceChanged() { root.generate(); }
    }

    Process {
        running: true
        command: ["sh", "-c", "command -v matugen"]
        onExited: code => root.available = code === 0
    }

    Process {
        id: generator
        stdout: StdioCollector {
            onStreamFinished: if (text.trim() !== "") root.parse(text)
        }
        stderr: StdioCollector {
            onStreamFinished: if (text.trim() !== "") console.warn("Umbra: matugen:", text.trim())
        }
    }

    FileView {
        id: file

        property bool loaded: false

        path: (Quickshell.env("XDG_STATE_HOME") || Quickshell.env("HOME") + "/.local/state") + "/umbra/colors.json"
        atomicWrites: true
        printErrors: false
        onLoaded: loaded = true
        onLoadFailed: error => {
            if (error !== FileViewError.FileNotFound)
                console.warn("Umbra: cannot read color state:", FileViewError.toString(error));
        }

        JsonAdapter {
            id: adapter
            property bool matugen: false
        }
    }
}
