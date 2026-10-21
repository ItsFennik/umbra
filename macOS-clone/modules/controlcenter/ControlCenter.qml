import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.components
import qs.config
import qs.services

// Toggle with: qs -p <umbra dir> ipc call controlcenter toggle
Scope {
    id: root

    IpcHandler {
        target: "controlcenter"

        function toggle(): void { Panels.toggle("controlcenter"); }
        function open(): void { Panels.open("controlcenter"); }
        function close(): void { Panels.close(); }
    }

    LazyLoader {
        active: Panels.current === "controlcenter"

        PopupSurface {
            id: surface

            panelName: "controlcenter"
            BackgroundEffect.blurRegion: Region { item: Theme.blur ? panel : null }

            property string page: ""
            Component.onCompleted: Brightness.refresh()

            Rectangle {
                id: panel

                anchors { top: parent.top; right: parent.right; topMargin: Theme.panelGap; rightMargin: Theme.panelGap }
                width: 320
                height: content.implicitHeight + 20
                radius: Theme.radiusLarge
                color: Theme.popupBackground
                border { width: 1; color: Theme.dockBorder }
                clip: true

                opacity: 0
                Component.onCompleted: opacity = 1
                Behavior on opacity { NumberAnimation { duration: Theme.durationShort } }
                Behavior on height { NumberAnimation { duration: Theme.durationMedium; easing.type: Theme.easing } }

                MouseArea { anchors.fill: parent }

                Loader {
                    id: content
                    anchors { left: parent.left; right: parent.right; top: parent.top; margins: 10 }
                    sourceComponent: surface.page === "wifi" ? wifiPage : surface.page === "bluetooth" ? bluetoothPage : surface.page === "sound" ? soundPage : mainPage
                }
            }

            Component {
                id: wifiPage
                WifiPage { onBack: surface.page = "" }
            }

            Component {
                id: bluetoothPage
                BluetoothPage { onBack: surface.page = "" }
            }

            Component {
                id: soundPage
                SoundPage { onBack: surface.page = "" }
            }

            Component {
                id: mainPage

                Column {
                    spacing: 8

                    Row {
                        width: parent.width
                        spacing: 8

                        Module {
                            width: parent.width - side.width - parent.spacing
                            height: side.height
                            spacing: 10

                            ToggleRow {
                                width: parent.width
                                icon: NetworkService.wifiEnabled ? "wifi" : "wifi-off"
                                title: "Wi-Fi"
                                subtitle: NetworkService.wifiStatus
                                available: NetworkService.wifiAvailable
                                checked: NetworkService.wifiEnabled
                                hasDetails: true
                                onToggled: NetworkService.setWifiEnabled(!NetworkService.wifiEnabled)
                                onDetailsRequested: surface.page = "wifi"
                            }

                            ToggleRow {
                                width: parent.width
                                icon: BluetoothService.enabled ? "bluetooth" : "bluetooth-off"
                                title: "Bluetooth"
                                subtitle: BluetoothService.status
                                available: BluetoothService.available
                                checked: BluetoothService.enabled
                                hasDetails: true
                                onToggled: BluetoothService.setEnabled(!BluetoothService.enabled)
                                onDetailsRequested: surface.page = "bluetooth"
                            }

                            ToggleRow {
                                width: parent.width
                                visible: NetworkService.wiredDevice !== null
                                icon: "ethernet"
                                title: "Ethernet"
                                subtitle: NetworkService.wiredConnected ? "Connected" : "Not Connected"
                                checked: NetworkService.wiredConnected
                                enabled: false
                            }
                        }

                        Column {
                            id: side
                            width: 110
                            spacing: 8

                            Tile {
                                width: parent.width
                                icon: "moon"
                                title: "Focus"
                                checked: Notifications.doNotDisturb
                                onClicked: Notifications.doNotDisturb = !Notifications.doNotDisturb
                            }

                            Tile {
                                width: parent.width
                                icon: "contrast"
                                title: "Dark Mode"
                                checked: Appearance.dark
                                onClicked: Appearance.setDark(!Appearance.dark)
                            }
                        }
                    }

                    Module {
                        width: parent.width
                        visible: Brightness.available

                        SectionTitle { text: "Display" }

                        Slider {
                            width: parent.width
                            icon: "sun"
                            value: Brightness.value
                            onMoved: v => Brightness.set(v)
                        }
                    }

                    Module {
                        width: parent.width

                        Item {
                            width: parent.width
                            height: soundTitle.height

                            SectionTitle { id: soundTitle; text: "Sound" }

                            MouseArea {
                                id: outputs
                                anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                                width: 20
                                height: 20
                                visible: Audio.sinks.length > 0
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: surface.page = "sound"

                                Icon {
                                    anchors.centerIn: parent
                                    name: "chevron-right"
                                    size: 12
                                    color: outputs.containsMouse ? Theme.text : Theme.textSecondary
                                }
                            }
                        }

                        Slider {
                            width: parent.width
                            icon: Audio.icon
                            enabled: Audio.available
                            value: Audio.muted ? 0 : Audio.volume
                            onMoved: v => Audio.setVolume(v)
                        }
                    }

                    Module {
                        width: parent.width
                        padding: 4

                        ListItem {
                            width: parent.width
                            icon: "image"
                            text: "Wallpaper"
                            trailingIcon: "chevron-right"
                            onClicked: Panels.open("wallpaper", Panels.screen)
                        }

                        ListItem {
                            width: parent.width
                            visible: Matugen.available
                            icon: "droplet"
                            text: "Match Wallpaper Colors"
                            selected: Matugen.enabled
                            onClicked: Matugen.setEnabled(!Matugen.enabled)

                            Switch {
                                anchors { right: parent.right; rightMargin: 8; verticalCenter: parent.verticalCenter }
                                checked: Matugen.enabled
                                onToggled: on => Matugen.setEnabled(on)
                            }
                        }

                        ListItem {
                            width: parent.width
                            icon: "toggles"
                            text: "Umbra Settings…"
                            onClicked: {
                                Panels.close();
                                Settings.windowOpen = true;
                            }
                        }
                    }

                    NowPlaying {
                        width: parent.width
                        visible: Media.player !== null
                    }
                }
            }
        }
    }

    component SectionTitle: Text {
        color: Theme.text
        font { family: Theme.font; pixelSize: Theme.px(12); weight: Theme.weight(Font.DemiBold) }
    }
}
