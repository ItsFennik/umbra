pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// CPU, memory and network throughput from /proc. Samples only while something shows them
// (acquire/release), at the fastest interval any consumer asked for.
Singleton {
    id: root

    readonly property int historyLength: 60

    // Consumer key -> requested interval in ms.
    property var requests: ({})
    readonly property bool active: Object.keys(requests).length > 0
    readonly property int interval: active ? Math.min(...Object.values(requests)) : 2000
    property bool available: true

    // 0..1
    property real cpu: 0
    property var cpuHistory: []
    // Bytes
    property real memTotal: 0
    property real memUsed: 0
    property real swapTotal: 0
    property real swapUsed: 0
    readonly property real memory: memTotal > 0 ? memUsed / memTotal : 0
    property var memoryHistory: []
    // Bytes per second, summed over physical interfaces.
    property real rxRate: 0
    property real txRate: 0
    property var rxHistory: []
    property var txHistory: []

    property var last: null

    function acquire(key, ms) {
        const first = !active;
        requests = Object.assign({}, requests, { [key]: Math.max(500, ms || 2000) });
        if (first)
            sample();
    }

    function release(key) {
        const next = Object.assign({}, requests);
        delete next[key];
        requests = next;
        if (!active)
            last = null;
    }

    function push(history, value) {
        const next = history.concat([value]);
        return next.length > historyLength ? next.slice(next.length - historyLength) : next;
    }

    function sample() {
        try {
            stat.reload();
            meminfo.reload();
            netdev.reload();
            const now = Date.now();

            const cpuFields = stat.text().split("\n")[0].trim().split(/\s+/).slice(1).map(Number);
            const idle = cpuFields[3] + (cpuFields[4] || 0);
            const total = cpuFields.slice(0, 8).reduce((a, b) => a + (b || 0), 0);

            const mem = {};
            for (const line of meminfo.text().split("\n")) {
                const m = line.match(/^(\w+):\s+(\d+)/);
                if (m)
                    mem[m[1]] = Number(m[2]) * 1024;
            }

            let rx = 0, tx = 0;
            for (const line of netdev.text().split("\n").slice(2)) {
                const [name, rest] = line.split(":");
                if (!rest || /^(lo|veth|docker|br-|virbr|vnet)/.test(name.trim()))
                    continue;
                const f = rest.trim().split(/\s+/).map(Number);
                rx += f[0];
                tx += f[8];
            }

            if (last) {
                const dt = Math.max(0.001, (now - last.time) / 1000);
                const dTotal = total - last.total;
                cpu = dTotal > 0 ? Math.max(0, Math.min(1, 1 - (idle - last.idle) / dTotal)) : cpu;
                rxRate = Math.max(0, (rx - last.rx) / dt);
                txRate = Math.max(0, (tx - last.tx) / dt);
                cpuHistory = push(cpuHistory, cpu);
                rxHistory = push(rxHistory, rxRate);
                txHistory = push(txHistory, txRate);
            }
            memTotal = mem.MemTotal ?? 0;
            memUsed = memTotal - (mem.MemAvailable ?? mem.MemFree ?? 0);
            swapTotal = mem.SwapTotal ?? 0;
            swapUsed = swapTotal - (mem.SwapFree ?? 0);
            memoryHistory = push(memoryHistory, memory);
            last = { time: now, idle: idle, total: total, rx: rx, tx: tx };
            available = total > 0;
        } catch (e) {
            if (available)
                console.warn("Umbra: cannot read system stats:", e);
            available = false;
        }
    }

    // "1.4 GB", "820 KB/s"; bits switches to "Mb/s" style network units.
    function formatBytes(bytes, perSecond, bits) {
        const units = bits ? ["b", "Kb", "Mb", "Gb", "Tb"] : ["B", "KB", "MB", "GB", "TB"];
        let v = bits ? bytes * 8 : bytes, i = 0;
        while (v >= 1000 && i < units.length - 1) {
            v /= 1000;
            i++;
        }
        return (v >= 100 || i === 0 ? Math.round(v) : v.toFixed(1)) + " " + units[i] + (perSecond ? "/s" : "");
    }

    Timer {
        running: root.active
        interval: root.interval
        repeat: true
        onTriggered: root.sample()
    }

    FileView { id: stat; path: "/proc/stat"; blockLoading: true; printErrors: false }
    FileView { id: meminfo; path: "/proc/meminfo"; blockLoading: true; printErrors: false }
    FileView { id: netdev; path: "/proc/net/dev"; blockLoading: true; printErrors: false }
}
