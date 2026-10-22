import QtQuick
import qs.components
import qs.config
import qs.services

// Previous / play-pause / next buttons for the menu bar (off by default; add them in Settings > Menu Bar).
Row {
    id: root

    readonly property var player: Media.player

    visible: player !== null

    Repeater {
        model: [
            { icon: "previous", enabled: root.player?.canGoPrevious ?? false, run: () => root.player.previous() },
            { icon: root.player?.isPlaying ? "pause" : "play", enabled: root.player?.canTogglePlaying ?? false, run: () => root.player.togglePlaying() },
            { icon: "next", enabled: root.player?.canGoNext ?? false, run: () => root.player.next() }
        ]

        delegate: BarButton {
            required property var modelData

            anchors.verticalCenter: parent.verticalCenter
            implicitWidth: Theme.barHeight - 4
            enabled: modelData.enabled
            opacity: enabled ? 1 : 0.4
            onClicked: modelData.run()

            Icon { name: modelData.icon; size: 13 }
        }
    }
}
