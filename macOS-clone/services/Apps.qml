pragma Singleton
import QtQuick
import Quickshell

// Maps windows to desktop entries and builds the dock's app list.
Singleton {
    id: root

    function entryFor(window) {
        return window ? DesktopEntries.heuristicLookup(window.appId) : null;
    }

    function keyFor(window) {
        const entry = entryFor(window);
        return entry ? entry.id : window.appId;
    }

    function nameFor(window) {
        const entry = entryFor(window);
        return entry ? entry.name : (window?.appId ?? "");
    }

    function windowsFor(key) {
        return Compositor.windows.filter(w => keyFor(w) === key);
    }

    function iconFor(entry, appId) {
        return Quickshell.iconPath(entry ? entry.icon : appId, "application-x-executable");
    }

    // Ranked application search: name matches outrank generic names, keywords and comments.
    // boost(entry), when given, adds to the score of entries that already match.
    function search(query, limit, boost) {
        const q = query.trim().toLowerCase();
        if (q === "")
            return [];
        const score = entry => {
            const name = entry.name.toLowerCase();
            if (name === q) return 100;
            if (name.startsWith(q)) return 80;
            if (name.split(/[\s\-_.]+/).some(w => w.startsWith(q))) return 60;
            if (name.includes(q)) return 40;
            const generic = entry.genericName.toLowerCase();
            if (generic.startsWith(q) || entry.keywords.some(k => k.toLowerCase().startsWith(q))) return 30;
            if (generic.includes(q)) return 20;
            if (entry.comment.toLowerCase().includes(q)) return 10;
            // Subsequence match, e.g. "lbw" -> "LibreWolf".
            let i = 0;
            for (const c of name) if (c === q[i]) i++;
            return i === q.length ? 5 : 0;
        };
        return DesktopEntries.applications.values
            .filter(e => !e.noDisplay)
            .map(e => ({ entry: e, score: score(e) }))
            .filter(r => r.score > 0)
            .map(r => boost ? { entry: r.entry, score: r.score + boost(r.entry) } : r)
            .sort((a, b) => b.score - a.score || a.entry.name.localeCompare(b.entry.name))
            .slice(0, limit)
            .map(r => r.entry);
    }

    // Pinned apps first, then running apps that are not pinned.
    readonly property var dockApps: {
        // Touch the applications model so lookups re-run once entries load.
        const loaded = DesktopEntries.applications.values.length;
        const apps = [];
        for (const id of Pins.pinned) {
            const entry = DesktopEntries.byId(id);
            if (entry)
                apps.push({ key: entry.id, entry: entry, appId: id, pinned: true });
        }
        for (const window of Compositor.windows) {
            const key = keyFor(window);
            if (!apps.some(a => a.key === key))
                apps.push({ key: key, entry: entryFor(window), appId: window.appId, pinned: false });
        }
        return apps;
    }
}
