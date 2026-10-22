import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.components
import qs.config
import qs.services
import qs.modules.widgets

// Now Playing popout from the menu bar: artwork, track, progress, controls, volume and a switcher
// when several players are open. It follows Media.player, which stays put while paused.
//   qs -p <umbra dir> ipc call media toggle      (also: open, close, playPause, next, previous)
Scope {
    IpcHandler {
        target: "media"

        function toggle(): void { Panels.toggle("media"); }
        function open(): void { Panels.open("media"); }
        function close(): void { Panels.close(); }
        function playPause(): void { if (Media.player?.canTogglePlaying) Media.player.togglePlaying(); }
        function next(): void { if (Media.player?.canGoNext) Media.player.next(); }
        function previous(): void { if (Media.player?.canGoPrevious) Media.player.previous(); }
    }

    LazyLoader {
        active: Panels.current === "media"

        PopupSurface {
            id: surface

            panelName: "media"
            BackgroundEffect.blurRegion: Region { item: Theme.blur ? panel : null }

            readonly property var player: Media.player

            function time(seconds) {
                const s = Math.max(0, Math.floor(seconds));
                return Math.floor(s / 60) + ":" + String(s % 60).padStart(2, "0");
            }

            // MPRIS only reports position on request.
            Timer {
                running: surface.player?.isPlaying ?? false
                interval: 1000
                repeat: true
                triggeredOnStart: true
                onTriggered: surface.player.positionChanged()
            }

            Rectangle {
                id: panel

                // Centred under the bar item when opened from it, else at the right edge.
                x: Panels.anchorX < 0 ? parent.width - width - Theme.panelGap
                    : Math.max(Theme.panelGap, Math.min(parent.width - width - Theme.panelGap, Panels.anchorX - width / 2))
                y: Theme.panelGap
                width: 340
                height: content.implicitHeight + 28
                radius: Theme.radiusLarge
                color: Theme.popupBackground
                border { width: 1; color: Theme.dockBorder }
                clip: true

                opacity: 0
                Component.onCompleted: opacity = 1
                Behavior on opacity { NumberAnimation { duration: Theme.durationShort } }
                Behavior on height { NumberAnimation { duration: Theme.durationMedium; easing.type: Theme.easing } }

                MouseArea { anchors.fill: parent }

                Column {
                    id: content
                    anchors { left: parent.left; right: parent.right; top: parent.top; margins: 14 }
                    spacing: 12

                    Text {
                        visible: surface.player === null
                        width: parent.width
                        text: "Nothing is playing"
                        horizontalAlignment: Text.AlignHCenter
                        color: Theme.textSecondary
                        font { family: Theme.font; weight: Theme.fontWeight; pixelSize: Theme.px(13) }
                    }

                    Item {
                        visible: surface.player !== null
                        width: parent.width
                        height: 84

                        Rectangle {
                            id: art
                            width: 84
                            height: 84
                            radius: Theme.radiusMedium
                            color: Theme.tileOff
                            clip: true

                            Icon {
                                anchors.centerIn: parent
                                visible: cover.status !== Image.Ready
                                name: "music"
                                size: 28
                                color: Theme.textSecondary
                            }

                            Image {
                                id: cover
                                anchors.fill: parent
                                source: surface.player?.trackArtUrl ?? ""
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                                sourceSize { width: 168; height: 168 }
                            }
                        }

                        Column {
                            anchors { left: art.right; leftMargin: 12; right: parent.right; verticalCenter: parent.verticalCenter }
                            spacing: 2

                            Text {
                                width: parent.width
                                text: surface.player?.trackTitle || surface.player?.identity || ""
                                elide: Text.ElideRight
                                color: Theme.text
                                font { family: Theme.font; pixelSize: Theme.px(14); weight: Theme.weight(Font.DemiBold) }
                            }

                            Text {
                                width: parent.width
                                visible: text !== ""
                                text: surface.player?.trackArtist ?? ""
                                elide: Text.ElideRight
                                color: Theme.text
                                font { family: Theme.font; weight: Theme.fontWeight; pixelSize: Theme.px(12) }
                            }

                            Text {
                                width: parent.width
                                visible: text !== ""
                                text: surface.player?.trackAlbum ?? ""
                                elide: Text.ElideRight
                                color: Theme.textSecondary
                                font { family: Theme.font; weight: Theme.fontWeight; pixelSize: Theme.px(11) }
                            }

                            MouseArea {
                                visible: surface.player?.canRaise ?? false
                                width: openLabel.implicitWidth
                                height: openLabel.implicitHeight + 4
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    surface.player.raise();
                                    Panels.close();
                                }

                                Text {
                                    id: openLabel
                                    anchors.bottom: parent.bottom
                                    text: "Open " + (surface.player?.identity ?? "")
                                    color: Theme.accent
                                    font { family: Theme.font; weight: Theme.fontWeight; pixelSize: Theme.px(11) }
                                }
                            }
                        }
                    }

                    Spectrum {
                        visible: surface.player?.isPlaying ?? false
                        width: parent.width
                        height: 28
                        bars: 40
                        spacing: 3
                        centered: true
                    }

                    Item {
                        id: progress

                        readonly property real length: surface.player?.lengthSupported ? surface.player.length : 0
                        readonly property real ratio: length > 0 ? Math.min(1, surface.player.position / length) : 0

                        visible: surface.player !== null && length > 0
                        width: parent.width
                        height: 22

                        Rectangle {
                            id: track
                            anchors { left: parent.left; right: parent.right; top: parent.top }
                            height: 4
                            radius: 2
                            color: Theme.sliderTrack

                            Rectangle {
                                width: parent.width * progress.ratio
                                height: parent.height
                                radius: 2
                                color: Theme.text
                                Behavior on width { NumberAnimation { duration: Theme.ms(1000); easing.type: Easing.Linear } }
                            }
                        }

                        MouseArea {
                            anchors { fill: track; margins: -6 }
                            enabled: surface.player?.canSeek ?? false
                            cursorShape: Qt.PointingHandCursor
                            onClicked: mouse => surface.player.position = Math.max(0, Math.min(1, (mouse.x - 6) / track.width)) * progress.length
                        }

                        Text {
                            anchors { left: parent.left; bottom: parent.bottom }
                            text: surface.time(surface.player?.position ?? 0)
                            color: Theme.textSecondary
                            font { family: Theme.font; weight: Theme.fontWeight; pixelSize: Theme.px(10); features: { "tnum": 1 } }
                        }

                        Text {
                            anchors { right: parent.right; bottom: parent.bottom }
                            text: "-" + surface.time(progress.length - (surface.player?.position ?? 0))
                            color: Theme.textSecondary
                            font { family: Theme.font; weight: Theme.fontWeight; pixelSize: Theme.px(10); features: { "tnum": 1 } }
                        }
                    }

                    Row {
                        visible: surface.player !== null
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 18

                        Repeater {
                            model: [
                                { icon: "previous", size: 18, enabled: surface.player?.canGoPrevious, run: () => surface.player.previous() },
                                { icon: surface.player?.isPlaying ? "pause" : "play", size: 24, enabled: surface.player?.canTogglePlaying, run: () => surface.player.togglePlaying() },
                                { icon: "next", size: 18, enabled: surface.player?.canGoNext, run: () => surface.player.next() }
                            ]

                            delegate: MouseArea {
                                id: control
                                required property var modelData
                                width: 40
                                height: 40
                                enabled: modelData.enabled ?? false
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: modelData.run()

                                Rectangle {
                                    anchors.fill: parent
                                    radius: 20
                                    color: control.pressed ? Theme.hover : control.containsMouse ? Qt.alpha(Theme.hover, 0.6) : "transparent"
                                }

                                Icon {
                                    anchors.centerIn: parent
                                    name: control.modelData.icon
                                    size: control.modelData.size
                                    strokeWidth: 1.5
                                    color: control.enabled ? Theme.text : Theme.textSecondary
                                }
                            }
                        }
                    }

                    Slider {
                        visible: surface.player?.volumeSupported ?? false
                        width: parent.width
                        icon: "volume"
                        value: surface.player?.volume ?? 0
                        onMoved: v => surface.player.volume = v
                    }

                    // Switcher, only with more than one player.
                    Flow {
                        visible: Media.players.length > 1
                        width: parent.width
                        spacing: 6

                        Repeater {
                            model: Media.players

                            delegate: MouseArea {
                                id: chip
                                required property var modelData
                                readonly property bool current: modelData === Media.player

                                width: chipLabel.implicitWidth + 20
                                height: 24
                                cursorShape: Qt.PointingHandCursor
                                onClicked: Media.player = modelData

                                Rectangle {
                                    anchors.fill: parent
                                    radius: 12
                                    color: chip.current ? Theme.accent : Theme.tileOff
                                }

                                Text {
                                    id: chipLabel
                                    anchors.centerIn: parent
                                    text: chip.modelData.identity
                                    color: chip.current ? Theme.onAccent : Theme.text
                                    font { family: Theme.font; weight: Theme.fontWeight; pixelSize: Theme.px(11) }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
