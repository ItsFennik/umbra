pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

// Default output volume and device selection through PipeWire.
Singleton {
    id: root

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property bool available: Pipewire.ready && sink !== null && sink.audio !== null
    readonly property real volume: sink?.audio?.volume ?? 0
    readonly property bool muted: sink?.audio?.muted ?? false
    readonly property var sinks: Pipewire.nodes.values.filter(n => n.isSink && !n.isStream && n.audio)

    readonly property string icon: !available || muted || volume <= 0 ? "volume-x" : volume < 0.34 ? "volume" : volume < 0.67 ? "volume-1" : "volume-2"

    function setVolume(value) {
        if (!available)
            return;
        sink.audio.volume = Math.max(0, Math.min(1, value));
        if (muted && value > 0)
            sink.audio.muted = false;
    }

    function toggleMute() {
        if (available)
            sink.audio.muted = !sink.audio.muted;
    }

    function setOutput(node) {
        Pipewire.preferredDefaultAudioSink = node;
    }

    function deviceName(node) {
        return node.nickname || node.description || node.name;
    }

    PwObjectTracker {
        objects: [root.sink]
    }
}
