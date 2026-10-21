pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Backlight brightness through brightnessctl. `available` stays false when
// brightnessctl is missing or no backlight device exists (e.g. desktop monitors).
Singleton {
    id: root

    property bool available: false
    property real value: 0
    property string device: ""

    property real pending: -1

    function refresh() {
        probe.running = true;
    }

    function set(v) {
        if (!available)
            return;
        value = Math.max(0.01, Math.min(1, v));
        pending = value;
        if (!writer.running)
            flush();
    }

    function flush() {
        if (pending < 0)
            return;
        writer.command = ["brightnessctl", "--device=" + device, "--quiet", "set", Math.round(pending * 100) + "%"];
        pending = -1;
        writer.running = true;
    }

    Component.onCompleted: refresh()

    Process {
        id: probe
        command: ["brightnessctl", "--class=backlight", "--machine-readable", "info"]
        stdout: StdioCollector {
            onStreamFinished: {
                // device,class,current,percent,max
                const fields = text.trim().split("\n")[0]?.split(",") ?? [];
                root.available = fields.length >= 5 && Number(fields[4]) > 0;
                if (root.available) {
                    root.device = fields[0];
                    root.value = Number(fields[2]) / Number(fields[4]);
                }
            }
        }
    }

    // Coalesces rapid slider updates into sequential brightnessctl calls.
    Process {
        id: writer
        onExited: root.flush()
    }
}
