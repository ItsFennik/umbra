pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Named snapshots of Umbra's look and layout, stored in $XDG_STATE_HOME/umbra/profiles.json.
// A profile holds every Umbra setting (fonts, Dock, performance), light or dark mode, the
// wallpaper-color toggle, the wallpaper, desktop widgets and Dock pins. Icon and cursor themes
// are system-wide and need a restart, so profiles leave them alone.
Singleton {
    id: root

    readonly property var list: valid(adapter.profiles)
    readonly property string active: adapter.active ?? ""

    function valid(profiles) {
        try {
            return Array.from(profiles ?? []).filter(p => p && typeof p.name === "string" && p.name !== "");
        } catch (e) {
            console.warn("Umbra: ignoring malformed profiles:", e);
            return [];
        }
    }

    function find(name) {
        return list.find(p => p.name === name) ?? null;
    }

    function capture() {
        return {
            settings: Settings.snapshot(),
            dark: Appearance.dark,
            matugen: Matugen.enabled,
            wallpaper: Wallpaper.path,
            widgets: Widgets.list,
            pins: Array.from(Pins.pinned)
        };
    }

    // Saves the current setup under `name`, replacing a profile with that name.
    function save(name) {
        name = (name ?? "").trim();
        if (name === "")
            return false;
        const profile = Object.assign({ name: name, saved: new Date().toISOString() }, capture());
        const existing = list.findIndex(p => p.name === name);
        adapter.profiles = existing < 0 ? list.concat([profile]) : list.map((p, i) => i === existing ? profile : p);
        adapter.active = name;
        file.writeAdapter();
        return true;
    }

    // Applies each part separately, so one bad value does not stop the rest.
    function apply(name) {
        const p = find(name);
        if (!p) {
            console.warn("Umbra: no profile named", name);
            return false;
        }
        const steps = {
            settings: () => { if (p.settings) Settings.setMany(p.settings); },
            dark: () => { if (typeof p.dark === "boolean" && Appearance.detected && p.dark !== Appearance.dark) Appearance.setDark(p.dark); },
            matugen: () => { if (typeof p.matugen === "boolean" && p.matugen !== Matugen.enabled) Matugen.setEnabled(p.matugen); },
            wallpaper: () => { if (typeof p.wallpaper === "string" && p.wallpaper !== "" && p.wallpaper !== Wallpaper.path) Wallpaper.set(p.wallpaper); },
            widgets: () => { if (p.widgets) Widgets.restore(p.widgets); },
            pins: () => { if (p.pins) Pins.save(Array.from(p.pins).filter(k => typeof k === "string")); }
        };
        for (const part in steps) {
            try {
                steps[part]();
            } catch (e) {
                console.warn("Umbra: profile", name, "could not restore", part + ":", e);
            }
        }
        adapter.active = name;
        file.writeAdapter();
        return true;
    }

    function remove(name) {
        adapter.profiles = list.filter(p => p.name !== name);
        if (active === name)
            adapter.active = "";
        file.writeAdapter();
    }

    function rename(from, to) {
        to = (to ?? "").trim();
        if (to === "" || find(to))
            return false;
        adapter.profiles = list.map(p => p.name === from ? Object.assign({}, p, { name: to }) : p);
        if (active === from)
            adapter.active = to;
        file.writeAdapter();
        return true;
    }

    // "Dark · 3 widgets · forest.png"
    function describe(p) {
        const parts = [p.dark === false ? "Light" : "Dark"];
        const widgets = Widgets.valid(p.widgets).length;
        parts.push(widgets === 1 ? "1 widget" : widgets + " widgets");
        if (typeof p.wallpaper === "string" && p.wallpaper !== "")
            parts.push(p.wallpaper.split("/").pop());
        return parts.join(" · ");
    }

    FileView {
        id: file

        path: (Quickshell.env("XDG_STATE_HOME") || Quickshell.env("HOME") + "/.local/state") + "/umbra/profiles.json"
        atomicWrites: true
        printErrors: false
        watchChanges: true
        onFileChanged: reload()
        onLoadFailed: error => {
            if (error !== FileViewError.FileNotFound)
                console.warn("Umbra: cannot read profiles:", FileViewError.toString(error));
        }

        JsonAdapter {
            id: adapter
            property var profiles: []
            property string active: ""
        }
    }
}
