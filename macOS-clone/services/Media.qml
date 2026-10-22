pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Mpris

// The MPRIS player to show. A player that starts playing takes over; otherwise the last one shown
// stays (so pausing keeps it), falling back to one with a track, then to any controllable player.
Singleton {
    id: root

    readonly property var players: Mpris.players.values.filter(p => p.canControl)
    property var player: null

    function pick() {
        const playing = players.find(p => p.isPlaying);
        if (playing)
            player = playing;
        else if (!player || !players.includes(player))
            player = players.find(p => p.trackTitle !== "") ?? players[0] ?? null;
    }

    onPlayersChanged: pick()
    Component.onCompleted: pick()

    Instantiator {
        model: Mpris.players

        delegate: Connections {
            required property MprisPlayer modelData
            target: modelData
            function onPlaybackStateChanged() { root.pick(); }
            function onCanControlChanged() { root.pick(); }
        }
    }
}
