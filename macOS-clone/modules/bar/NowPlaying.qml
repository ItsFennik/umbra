import QtQuick
import qs.components
import qs.config
import qs.services

// Current track in the menu bar: cover art and title, then previous / play-pause / next.
// Clicking the title opens the Now Playing popout; scrolling skips tracks. Stays while paused.
Row {
    id: root

    required property var screen
    readonly property var player: Media.player

    visible: Settings.barShowMedia && player !== null
    spacing: 0

    BarButton {
        anchors.verticalCenter: parent.verticalCenter
        active: Panels.current === "media"
        onClicked: Panels.toggle("media", root.screen, root.mapToItem(null, root.width / 2, 0).x)
        onWheel: event => {
            if (event.angleDelta.y > 0 && root.player.canGoPrevious)
                root.player.previous();
            else if (event.angleDelta.y < 0 && root.player.canGoNext)
                root.player.next();
        }

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: Theme.barHeight - 12
            height: width
            radius: 3
            color: Theme.tileOff
            clip: true

            Icon {
                anchors.centerIn: parent
                visible: art.status !== Image.Ready
                name: "music"
                size: 11
            }

            Image {
                id: art
                anchors.fill: parent
                source: root.player?.trackArtUrl ?? ""
                sourceSize { width: 48; height: 48 }
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
            }
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            width: Math.min(implicitWidth, Theme.px(220))
            text: [root.player?.trackTitle || root.player?.identity, root.player?.trackArtist].filter(s => s).join(" — ")
            elide: Text.ElideRight
            color: Theme.text
            font { family: Theme.font; pixelSize: Theme.fontSize; weight: Theme.weight(Font.Medium) }
        }
    }

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
