pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Audio spectrum from cava, 0..1 per bar. Runs only while something that shows it is
// on screen (acquire/release) and a player is playing; restarts cava if it dies.
Singleton {
    id: root

    readonly property int count: 48
    readonly property var silence: new Array(count).fill(0)
    property var levels: silence

    property int consumers: 0
    readonly property bool active: consumers > 0 && (Media.player?.isPlaying ?? false)

    function acquire() { consumers++; }
    function release() { consumers = Math.max(0, consumers - 1); }

    // Level at t in 0..1 from bass to treble, interpolated so widgets can draw any number of bars.
    function at(t) {
        const p = Math.max(0, Math.min(1, t)) * (count - 1);
        const i = Math.floor(p);
        const a = levels[i] ?? 0;
        return a + ((levels[Math.min(count - 1, i + 1)] ?? 0) - a) * (p - i);
    }

    onActiveChanged: {
        process.running = active;
        if (!active)
            levels = silence;
    }

    Process {
        id: process

        command: ["bash", "-c", "exec cava -p <(printf '%s' \"$1\")", "cava", [
            "[general]",
            "bars = " + root.count,
            "framerate = 60",
            "autosens = 1",
            "[output]",
            "method = raw",
            "channels = mono",
            "raw_target = /dev/stdout",
            "data_format = ascii",
            "ascii_max_range = 1000",
            "bar_delimiter = 59",
            "[smoothing]",
            "monstercat = 1",
            "noise_reduction = 70",
            ""
        ].join("\n")]

        stdout: SplitParser {
            onRead: line => {
                const parts = line.split(";");
                const next = new Array(root.count);
                for (let i = 0; i < root.count; i++)
                    next[i] = Math.min(1, (parseInt(parts[i]) || 0) / 1000);
                root.levels = next;
            }
        }

        onExited: code => {
            if (root.active)
                restart.start();
        }
    }

    Timer {
        id: restart
        interval: 1000
        onTriggered: {
            if (!root.active)
                return;
            console.warn("Umbra: cava exited, restarting");
            process.running = true;
        }
    }
}
