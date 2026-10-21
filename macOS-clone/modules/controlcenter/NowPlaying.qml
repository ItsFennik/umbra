import QtQuick
import qs.components
import qs.config
import qs.services

Module {
    id: root

    readonly property var player: Media.player

    Item {
        width: parent.width
        height: 44

        Rectangle {
            id: art
            width: 44
            height: 44
            radius: Theme.radiusSmall
            color: Theme.tileOff
            clip: true

            Image {
                anchors.fill: parent
                source: root.player?.trackArtUrl ?? ""
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                sourceSize { width: 88; height: 88 }
            }
        }

        Column {
            anchors { left: art.right; leftMargin: 10; right: controls.left; rightMargin: 8; verticalCenter: parent.verticalCenter }

            Text {
                width: parent.width
                text: root.player?.trackTitle || root.player?.identity || ""
                elide: Text.ElideRight
                color: Theme.text
                font { family: Theme.font; pixelSize: Theme.px(13); weight: Theme.weight(Font.DemiBold) }
            }

            Text {
                width: parent.width
                text: root.player?.trackArtist || root.player?.identity || ""
                elide: Text.ElideRight
                color: Theme.textSecondary
                font { family: Theme.font; weight: Theme.fontWeight; pixelSize: Theme.px(11) }
            }
        }

        Row {
            id: controls
            anchors { right: parent.right; verticalCenter: parent.verticalCenter }
            spacing: 2

            Repeater {
                model: [
                    { icon: "previous", enabled: root.player?.canGoPrevious, run: () => root.player.previous() },
                    { icon: root.player?.isPlaying ? "pause" : "play", enabled: root.player?.canTogglePlaying, run: () => root.player.togglePlaying() },
                    { icon: "next", enabled: root.player?.canGoNext, run: () => root.player.next() }
                ]

                delegate: MouseArea {
                    id: control
                    required property var modelData
                    width: 28
                    height: 28
                    enabled: modelData.enabled ?? false
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: modelData.run()

                    Rectangle {
                        anchors.fill: parent
                        radius: 14
                        color: control.containsMouse ? Theme.hover : "transparent"
                    }

                    Icon {
                        anchors.centerIn: parent
                        name: control.modelData.icon
                        size: 14
                        strokeWidth: 1.5
                        color: control.enabled ? Theme.text : Theme.textSecondary
                    }
                }
            }
        }
    }
}
