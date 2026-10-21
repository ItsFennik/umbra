import QtQuick
import qs.components
import qs.config
import qs.services

Column {
    spacing: 20

    SettingsGroup {
        SettingsRow {
            title: "Appearance"
            subtitle: Appearance.detected ? "" : "Needs gsettings"
            enabled: Appearance.detected
            implicitHeight: 112

            Row {
                spacing: 14

                Repeater {
                    model: [{ dark: false, text: "Light" }, { dark: true, text: "Dark" }]

                    delegate: MouseArea {
                        id: card
                        required property var modelData
                        readonly property bool current: Appearance.dark === modelData.dark

                        width: 76
                        height: 80
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Appearance.setDark(modelData.dark)

                        // Miniature desktop: wallpaper-ish backdrop, menu bar and a window.
                        Rectangle {
                            id: thumb
                            width: parent.width
                            height: 50
                            radius: 7
                            color: card.modelData.dark ? "#1c1c22" : "#dfe6f0"
                            border { width: card.current ? 3 : 1; color: card.current ? Theme.accent : Theme.hairline }

                            Rectangle {
                                anchors { left: parent.left; right: parent.right; top: parent.top; margins: 4 }
                                height: 5
                                radius: 2
                                color: card.modelData.dark ? "#3a3a40" : "#ffffff"
                            }

                            Rectangle {
                                x: 12
                                y: 14
                                width: 44
                                height: 28
                                radius: 3
                                color: card.modelData.dark ? "#2c2c32" : "#ffffff"

                                Rectangle {
                                    x: 4; y: 4; width: 20; height: 3; radius: 1.5
                                    color: Theme.accent
                                }
                            }
                        }

                        Text {
                            anchors { horizontalCenter: parent.horizontalCenter; top: thumb.bottom; topMargin: 6 }
                            text: card.modelData.text
                            color: Theme.text
                            font { family: Theme.font; pixelSize: Theme.px(12); weight: Theme.weight(card.current ? Font.DemiBold : Font.Normal) }
                        }
                    }
                }
            }
        }
    }

    SettingsGroup {
        title: "Colors"
        footer: Matugen.available ? "Uses matugen to build a Material You palette from the wallpaper; it is regenerated whenever the wallpaper changes." : ""

        SettingsRow {
            title: "Match Wallpaper Colors"
            subtitle: Matugen.available ? "Accent, text and surfaces follow the wallpaper" : "Install matugen to enable"
            enabled: Matugen.available

            Switch {
                checked: Matugen.enabled
                onToggled: on => Matugen.setEnabled(on)
            }
        }

        SettingsRow {
            title: "Palette"
            visible: Matugen.active

            Row {
                spacing: 6

                Repeater {
                    model: ["primary", "secondary", "tertiary", "surface_container", "on_surface"]

                    delegate: Rectangle {
                        required property string modelData
                        width: 18
                        height: 18
                        radius: 9
                        color: Matugen.colors[modelData] ?? "transparent"
                        border { width: 1; color: Theme.hairline }
                    }
                }
            }
        }
    }
}
