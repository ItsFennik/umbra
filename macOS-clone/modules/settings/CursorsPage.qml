import QtQuick
import qs.components
import qs.config
import qs.services

Column {
    spacing: 20

    SettingsGroup {
        title: "Size"

        SettingsRow {
            title: "Cursor size"
            enabled: Themes.cursorTheme !== ""

            Row {
                spacing: 4

                Repeater {
                    model: [24, 32, 48, 64]

                    delegate: MouseArea {
                        id: option
                        required property int modelData
                        readonly property bool current: Themes.cursorSize === modelData

                        width: 44
                        height: 24
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Themes.setCursor(Themes.cursorTheme, modelData)

                        Rectangle {
                            anchors.fill: parent
                            radius: Theme.radiusSmall
                            color: option.current ? Theme.accent : Theme.tileOff
                        }

                        Text {
                            anchors.centerIn: parent
                            text: option.modelData
                            color: option.current ? Theme.onAccent : Theme.text
                            font { family: Theme.font; weight: Theme.fontWeight; pixelSize: Theme.px(12) }
                        }
                    }
                }
            }
        }
    }

    SettingsGroup {
        title: "Cursor Theme"
        footer: "Applies right away in Hyprland and is saved for GTK, Qt and X11 apps."

        Repeater {
            model: Themes.cursorThemes

            delegate: SettingsRow {
                id: row
                required property string modelData

                title: modelData
                cursorShape: Qt.PointingHandCursor
                onClicked: Themes.setCursor(modelData, Themes.cursorSize)

                Icon {
                    visible: Themes.cursorTheme === row.modelData
                    name: "check"
                    size: 14
                    color: Theme.accent
                }
            }
        }
    }
}
