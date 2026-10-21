import QtQuick
import QtQuick.Effects
import qs.components
import qs.config
import qs.services

// Now Playing: artwork, track, controls, cava spectrum and progress, over a blur of the artwork.
Item {
    id: root

    readonly property var player: Media.player
    readonly property bool tinted: backdrop.status === Image.Ready
    readonly property color foreground: tinted ? "white" : Theme.text
    readonly property color secondary: tinted ? Qt.rgba(1, 1, 1, 0.65) : Theme.textSecondary
    readonly property real radius: 22

    function time(seconds) {
        const s = Math.max(0, Math.floor(seconds));
        return Math.floor(s / 60) + ":" + String(s % 60).padStart(2, "0");
    }

    // MPRIS only reports position on request.
    Timer {
        running: root.player?.isPlaying ?? false
        interval: 1000
        repeat: true
        onTriggered: root.player.positionChanged()
    }

    // Background, clipped to the rounded card.
    Item {
        anchors.fill: parent
        layer.enabled: true
        layer.effect: MultiEffect {
            maskEnabled: true
            maskSource: mask
            maskThresholdMin: 0.5
            maskSpreadAtMin: 1
        }

        Rectangle {
            anchors.fill: parent
            color: Theme.popupBackground
        }

        Image {
            id: backdrop
            anchors.fill: parent
            source: root.player?.trackArtUrl ?? ""
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            sourceSize { width: 96; height: 96 }
            visible: false
        }

        MultiEffect {
            anchors.fill: parent
            source: backdrop
            visible: root.tinted
            blurEnabled: true
            blur: 1
            blurMax: 64
            saturation: 0.2
            brightness: -0.3
            opacity: 0.85
        }
    }

    Item {
        id: mask
        anchors.fill: parent
        layer.enabled: true
        visible: false

        Rectangle {
            anchors.fill: parent
            radius: root.radius
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: root.radius
        color: "transparent"
        border { width: 1; color: Theme.dockBorder }
    }

    Item {
        anchors { fill: parent; margins: 16 }

        Rectangle {
            id: art
            width: 64
            height: 64
            radius: 12
            color: Theme.tileOff
            clip: true

            Icon {
                anchors.centerIn: parent
                visible: cover.status !== Image.Ready
                name: "music"
                size: 26
                color: root.secondary
            }

            Image {
                id: cover
                anchors.fill: parent
                source: root.player?.trackArtUrl ?? ""
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                sourceSize { width: 128; height: 128 }
            }
        }

        Column {
            anchors { left: art.right; leftMargin: 12; right: controls.left; rightMargin: 8; verticalCenter: art.verticalCenter }
            spacing: 2

            Text {
                width: parent.width
                text: root.player?.trackTitle || root.player?.identity || "Not Playing"
                elide: Text.ElideRight
                color: root.foreground
                font { family: Theme.font; pixelSize: 15; weight: Font.DemiBold }
            }

            Text {
                width: parent.width
                visible: text !== ""
                text: root.player?.trackArtist ?? ""
                elide: Text.ElideRight
                color: root.secondary
                font { family: Theme.font; pixelSize: 12 }
            }

            Text {
                width: parent.width
                visible: text !== ""
                text: root.player?.trackTitle ? root.player.identity : ""
                elide: Text.ElideRight
                color: root.secondary
                font { family: Theme.font; pixelSize: 10; weight: Font.Medium; capitalization: Font.AllUppercase; letterSpacing: 0.6 }
            }
        }

        Row {
            id: controls
            anchors { right: parent.right; verticalCenter: art.verticalCenter }
            spacing: 2

            Repeater {
                model: [
                    { icon: "previous", size: 14, enabled: root.player?.canGoPrevious, run: () => root.player.previous() },
                    { icon: root.player?.isPlaying ? "pause" : "play", size: 18, enabled: root.player?.canTogglePlaying, run: () => root.player.togglePlaying() },
                    { icon: "next", size: 14, enabled: root.player?.canGoNext, run: () => root.player.next() }
                ]

                delegate: MouseArea {
                    id: control
                    required property var modelData
                    width: 32
                    height: 32
                    enabled: modelData.enabled ?? false
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: modelData.run()

                    Rectangle {
                        anchors.fill: parent
                        radius: 16
                        color: control.containsMouse ? Qt.rgba(1, 1, 1, root.tinted ? 0.16 : 0) : "transparent"
                        border { width: control.containsMouse && !root.tinted ? 1 : 0; color: Theme.hairline }
                    }

                    Icon {
                        anchors.centerIn: parent
                        name: control.modelData.icon
                        size: control.modelData.size
                        strokeWidth: 1.5
                        color: control.enabled ? root.foreground : root.secondary
                    }
                }
            }
        }

        Spectrum {
            anchors { left: parent.left; right: parent.right; top: art.bottom; topMargin: 10; bottom: progress.top; bottomMargin: 8 }
            bars: 40
            spacing: 3
            color: root.tinted ? Qt.rgba(1, 1, 1, 0.85) : Theme.accent
        }

        Item {
            id: progress
            anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
            height: 20

            readonly property real length: root.player?.lengthSupported ? root.player.length : 0
            readonly property real ratio: length > 0 ? Math.min(1, root.player.position / length) : 0

            Rectangle {
                id: track
                anchors { left: parent.left; right: parent.right; top: parent.top }
                height: 4
                radius: 2
                color: root.tinted ? Qt.rgba(1, 1, 1, 0.2) : Theme.sliderTrack

                Rectangle {
                    width: parent.width * progress.ratio
                    height: parent.height
                    radius: 2
                    color: root.foreground
                    Behavior on width { NumberAnimation { duration: 1000; easing.type: Easing.Linear } }
                }
            }

            MouseArea {
                anchors { fill: track; margins: -6 }
                enabled: (root.player?.canSeek ?? false) && progress.length > 0
                cursorShape: Qt.PointingHandCursor
                onClicked: mouse => root.player.position = Math.max(0, Math.min(1, (mouse.x - 6) / track.width)) * progress.length
            }

            Text {
                anchors { left: parent.left; bottom: parent.bottom }
                text: root.time(root.player?.position ?? 0)
                color: root.secondary
                font { family: Theme.font; pixelSize: 10; features: { "tnum": 1 } }
            }

            Text {
                anchors { right: parent.right; bottom: parent.bottom }
                text: progress.length > 0 ? "-" + root.time(progress.length - (root.player?.position ?? 0)) : ""
                color: root.secondary
                font { family: Theme.font; pixelSize: 10; features: { "tnum": 1 } }
            }
        }
    }
}
