pragma Singleton
import QtQuick
import Quickshell
import qs.services

// What the menu bar can hold and where each item sits (Settings > Menu Bar, stored as barLayout).
Singleton {
    id: root

    readonly property var items: [
        { id: "logo", text: "Umbra Menu", icon: "moon" },
        { id: "activeApp", text: "App Name", icon: "type" },
        { id: "workspaces", text: "Workspaces", icon: "workspaces" },
        { id: "nowPlaying", text: "Now Playing", icon: "music" },
        { id: "mediaControls", text: "Playback Controls", icon: "play" },
        { id: "tray", text: "Tray", icon: "grid" },
        { id: "battery", text: "Battery", icon: "battery" },
        { id: "network", text: "Network", icon: "wifi" },
        { id: "volume", text: "Volume", icon: "volume" },
        { id: "controlCenter", text: "Control Center", icon: "toggles" },
        { id: "clock", text: "Clock", icon: "clock" },
        { id: "power", text: "Power", icon: "power" }
    ]
    readonly property var zones: ["left", "center", "right"]

    function find(id) {
        return items.find(i => i.id === id) ?? null;
    }

    // Settings.barLayout with unknown and repeated items dropped, so a hand-edited file cannot break the bar.
    readonly property var layout: {
        const raw = Settings.barLayout ?? {};
        const seen = new Set();
        const out = {};
        for (const zone of zones) {
            out[zone] = Array.from(raw[zone] ?? []).filter(id => {
                if (typeof id !== "string" || !find(id) || seen.has(id))
                    return false;
                seen.add(id);
                return true;
            });
        }
        return out;
    }
    readonly property var unused: items.map(i => i.id).filter(id => !zones.some(z => layout[z].includes(id)))

    // Moves `id` to `zone` at `index` ("unused" removes it from the bar).
    function move(id, zone, index) {
        const next = {};
        for (const z of zones)
            next[z] = layout[z].filter(i => i !== id);
        if (zone !== "unused")
            next[zone].splice(Math.max(0, Math.min(index, next[zone].length)), 0, id);
        Settings.set("barLayout", next);
    }
}
