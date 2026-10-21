pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Mpris

// The MPRIS player to show: the playing one, else the first controllable one.
Singleton {
    readonly property var players: Mpris.players.values.filter(p => p.canControl)
    readonly property var player: players.find(p => p.isPlaying) ?? players[0] ?? null
}
