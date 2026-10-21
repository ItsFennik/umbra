pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Desktop widgets.
//
// Types register themselves: every modules/widgets/<id>/ folder holding a manifest.json and a
// Widget.qml (a WidgetBase) is a widget type, picked up at startup and on reload(). manifest.json:
//   { "name", "description", "icon", "width", "height", "minWidth", "minHeight", "maxWidth",
//     "maxHeight", "resizable", "glass", "order",
//     "settings": [{ "key", "label", "type": "bool" | "range" | "choice" | "text", "default",
//                    "from", "to", "step", "unit"  (range), "options": [{ "value", "text" }] (choice) }] }
// Settings > Widgets builds each widget's controls from "settings"; the widget reads them as `options`.
//
// Placed widgets are stored in $XDG_STATE_HOME/umbra/widgets.json as
//   [{ id, type, screen, x, y, width?, height?, options? }]
// with x and y in screen coordinates of the named screen. List order is stacking order, front last.
Singleton {
    id: root

    // Registered types, from the manifests; glass means a blurred background behind the widget.
    property var types: []
    property bool scanned: false

    readonly property var list: valid(adapter.widgets)

    readonly property string directory: Quickshell.shellDir + "/modules/widgets"

    // JsonAdapter hands back a list type that is not a JS array, so copy it.
    function valid(widgets) {
        try {
            return Array.from(widgets ?? []).filter(w => w && w.id && w.type);
        } catch (e) {
            console.warn("Umbra: ignoring malformed widget list:", e);
            return [];
        }
    }

    function type(id) {
        return types.find(t => t.id === id) ?? null;
    }

    function entry(id) {
        return list.find(w => w.id === id) ?? null;
    }

    function reload() {
        scan.running = false;
        scan.running = true;
    }

    // Widgets on a screen. Ones whose screen is gone show on the first screen.
    function on(screen) {
        const names = Quickshell.screens.map(s => s.name);
        return list.filter(w => w.screen === screen.name || (!names.includes(w.screen) && screen === Quickshell.screens[0]));
    }

    function defaults(t) {
        const values = {};
        for (const s of t?.settings ?? [])
            values[s.key] = s.default;
        return values;
    }

    function optionsFor(w) {
        return Object.assign(defaults(type(w?.type)), w?.options ?? {});
    }

    function clampSize(t, width, height) {
        return {
            width: Math.round(Math.max(t.minWidth, Math.min(t.maxWidth, width))),
            height: Math.round(Math.max(t.minHeight, Math.min(t.maxHeight, height)))
        };
    }

    function sizeOf(w) {
        const t = type(w?.type);
        if (!t)
            return { width: 0, height: 0 };
        return t.resizable ? clampSize(t, w.width ?? t.width, w.height ?? t.height) : { width: t.width, height: t.height };
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

    function update(id, changes) {
        save(list.map(w => w.id === id ? Object.assign({}, w, changes) : w));
    }

    function move(id, x, y) {
        update(id, { x: Math.round(x), y: Math.round(y) });
    }

    function setGeometry(id, x, y, width, height) {
        const t = type(entry(id)?.type);
        if (!t)
            return;
        update(id, Object.assign({ x: Math.round(x), y: Math.round(y) }, clampSize(t, width, height)));
    }

    function resetSize(id) {
        save(list.map(w => {
            if (w.id !== id)
                return w;
            const copy = Object.assign({}, w);
            delete copy.width;
            delete copy.height;
            return copy;
        }));
    }

    function configure(id, key, value) {
        const w = entry(id);
        if (w)
            update(id, { options: Object.assign({}, w.options ?? {}, { [key]: value }) });
    }

    function resetOptions(id) {
        update(id, { options: {} });
    }

    // Stacking: the last widget is drawn in front.
    function reorder(from, to) {
        if (from === to || from < 0 || from >= list.length)
            return;
        const next = list.slice();
        const [moved] = next.splice(from, 1);
        next.splice(Math.max(0, Math.min(next.length, to)), 0, moved);
        save(next);
    }

    function raise(id) {
        const i = list.findIndex(w => w.id === id);
        reorder(i, list.length - 1);
    }

    function lower(id) {
        reorder(list.findIndex(w => w.id === id), 0);
    }

    function remove(id) {
        save(list.filter(w => w.id !== id));
    }

    function clear() {
        save([]);
    }

    // Replaces the whole layout, e.g. from a profile.
    function restore(widgets) {
        save(valid(widgets));
    }

    function save(widgets) {
        adapter.widgets = widgets;
        file.writeAdapter();
    }

    function parseManifests(text) {
        const found = [];
        for (const chunk of text.split("\x1e")) {
            const newline = chunk.indexOf("\n");
            if (newline < 0)
                continue;
            const id = chunk.slice(0, newline).trim();
            let m;
            try {
                m = JSON.parse(chunk.slice(newline + 1));
            } catch (e) {
                console.warn("Umbra: widget", id, "has an invalid manifest.json:", e);
                continue;
            }
            if (!/^[A-Za-z0-9_-]+$/.test(id) || typeof m !== "object" || m === null) {
                console.warn("Umbra: skipping widget folder", id);
                continue;
            }
            const num = (v, fallback) => typeof v === "number" && isFinite(v) ? v : fallback;
            const width = num(m.width, 240), height = num(m.height, 160);
            const settings = (Array.isArray(m.settings) ? m.settings : []).filter(s => {
                const ok = s && typeof s.key === "string" && ["bool", "range", "choice", "text"].includes(s.type);
                if (!ok)
                    console.warn("Umbra: widget", id, "has an invalid setting", JSON.stringify(s));
                return ok;
            }).map(s => Object.assign({ label: s.key }, s, {
                options: Array.isArray(s.options) ? s.options : [],
                default: s.default ?? (s.type === "bool" ? false : s.type === "range" ? num(s.from, 0) : s.type === "choice" ? s.options?.[0]?.value ?? "" : "")
            }));
            found.push({
                id: id,
                text: typeof m.name === "string" ? m.name : id,
                description: typeof m.description === "string" ? m.description : "",
                icon: typeof m.icon === "string" ? m.icon : "grid",
                order: num(m.order, 100),
                width: width,
                height: height,
                resizable: m.resizable !== false,
                minWidth: num(m.minWidth, Math.round(width / 2)),
                minHeight: num(m.minHeight, Math.round(height / 2)),
                maxWidth: num(m.maxWidth, width * 3),
                maxHeight: num(m.maxHeight, height * 3),
                glass: m.glass === true,
                settings: settings
            });
        }
        types = found.sort((a, b) => a.order - b.order || a.text.localeCompare(b.text));
        scanned = true;
    }

    // Prints "\x1e<folder>\n<manifest.json>" for every folder with both files.
    Process {
        id: scan
        running: true
        command: ["sh", "-c", `
            for f in "$1"/*/manifest.json; do
                [ -f "$f" ] || continue
                d=\${f%/manifest.json}
                if [ ! -f "$d/Widget.qml" ]; then echo "\${d##*/} has no Widget.qml" >&2; continue; fi
                printf '\\036%s\\n' "\${d##*/}"
                cat "$f"
            done`, "sh", root.directory]
        stdout: StdioCollector {
            onStreamFinished: root.parseManifests(text)
        }
        stderr: StdioCollector {
            onStreamFinished: if (text.trim() !== "") console.warn("Umbra: widgets:", text.trim())
        }
    }

    FileView {
        id: file

        path: (Quickshell.env("XDG_STATE_HOME") || Quickshell.env("HOME") + "/.local/state") + "/umbra/widgets.json"
        atomicWrites: true
        printErrors: false
        // Picks up hand edits to widgets.json.
        watchChanges: true
        onFileChanged: reload()
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
