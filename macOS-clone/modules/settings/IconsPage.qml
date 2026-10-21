import QtQuick
import qs.components
import qs.config
import qs.services

Column {
    spacing: 20

    SettingsGroup {
        title: "Icon Theme"
        footer: "Applies to Umbra and to GTK and Qt apps (gsettings, qt5ct, qt6ct). Umbra restarts to load the new icons; apps pick them up when reopened."

        Repeater {
            model: Themes.iconThemes

            delegate: SettingsRow {
                id: row
                required property string modelData
                readonly property bool current: Themes.iconTheme === modelData

                title: modelData
                cursorShape: Qt.PointingHandCursor
                onClicked: if (!current) Themes.setIconTheme(modelData)

                Row {
                    spacing: 8

                    Repeater {
                        model: Themes.iconSamples[row.modelData] ?? []

                        delegate: Image {
                            required property string modelData
                            anchors.verticalCenter: parent.verticalCenter
                            width: 24
                            height: 24
                            source: "file://" + modelData
                            sourceSize { width: 48; height: 48 }
                            asynchronous: true
                        }
                    }

                    Item {
                        width: 16
                        height: 24

                        Icon {
                            anchors.centerIn: parent
                            visible: row.current
                            name: "check"
                            size: 14
                            color: Theme.accent
                        }
                    }
                }
            }
        }
    }
}
