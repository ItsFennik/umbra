import QtQuick
import qs.components
import qs.config
import qs.services

// Optional previous / play-pause / next buttons for the menu bar (Settings > Desktop & Dock).
Row {
    id: root

    readonly property var player: Media.player

    visible: Settings.barMediaControls && player !== null

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
