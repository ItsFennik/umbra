pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Desktop widgets, stored in $XDG_STATE_HOME/umbra/widgets.json as
//   [{ id, type, screen, x, y }]
// with x and y in screen coordinates of the named screen.
Singleton {
    id: root

    // glass: blurred background behind the widget.
    readonly property var types: [
        { id: "music", text: "Now Playing", width: 360, height: 176, glass: true },
        { id: "visualizer", text: "Visualizer", width: 480, height: 120 },
        { id: "clock", text: "Clock", width: 320, height: 150 }
    ]

    readonly property var list: adapter.widgets ?? []

    function type(id) {
        return types.find(t => t.id === id) ?? null;
    }

    // Widgets on a screen. Ones whose screen is gone show on the first screen.
    function on(screen) {
        const names = Quickshell.screens.map(s => s.name);
        return list.filter(w => w.screen === screen.name || (!names.includes(w.screen) && screen === Quickshell.screens[0]));
    }

    // Adds a widget centered on (x, y), or on the screen when not given.
    function add(typeId, screen, x, y) {
        const t = type(typeId);
        if (!t) {
            console.warn("Umbra: unknown widget type", typeId);
            return;
        }
        screen = screen ?? Quickshell.screens[0];
        const cx = x ?? screen.width / 2;
        const cy = y ?? screen.height / 2;
        save(list.concat([{
            id: Date.now().toString(36) + Math.random().toString(36).slice(2, 6),
            type: typeId,
            screen: screen.name,
            x: Math.round(Math.max(0, Math.min(cx - t.width / 2, screen.width - t.width))),
            y: Math.round(Math.max(0, Math.min(cy - t.height / 2, screen.height - t.height)))
        }]));
    }

    function move(id, x, y) {
        save(list.map(w => w.id === id ? Object.assign({}, w, { x: Math.round(x), y: Math.round(y) }) : w));
    }

    function remove(id) {
        save(list.filter(w => w.id !== id));
    }

    function clear() {
        save([]);
    }

    function save(widgets) {
        adapter.widgets = widgets;
        file.writeAdapter();
    }

    FileView {
        id: file

        path: (Quickshell.env("XDG_STATE_HOME") || Quickshell.env("HOME") + "/.local/state") + "/umbra/widgets.json"
        atomicWrites: true
        printErrors: false
        onLoadFailed: error => {
            if (error !== FileViewError.FileNotFound)
                console.warn("Umbra: cannot read widgets:", FileViewError.toString(error));
        }

        JsonAdapter {
            id: adapter
            property var widgets: []
        }
    }
}
