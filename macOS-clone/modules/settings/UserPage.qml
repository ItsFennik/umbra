import QtQuick
import qs.config
import qs.services

Column {
    spacing: 20

    Column {
        width: parent.width
        spacing: 10

        Avatar {
            anchors.horizontalCenter: parent.horizontalCenter
            size: 96
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: User.name
            color: Theme.text
            font { family: Theme.font; pixelSize: Theme.px(18); weight: Theme.weight(Font.Bold) }
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: User.login
            color: Theme.textSecondary
            font { family: Theme.font; weight: Theme.fontWeight; pixelSize: Theme.px(12) }
        }
    }

    SettingsGroup {
        footer: "The picture is saved to ~/.face, which login screens such as SDDM and GDM also use."

        SettingsRow {
            title: "Profile Picture"
            subtitle: User.canPick ? "" : "Install zenity to choose a file"

            Row {
                spacing: 6

                PushButton {
                    text: "Remove"
                    enabled: User.hasFace
                    onClicked: User.removePicture()
                }

                PushButton {
                    text: "Use Wallpaper"
                    onClicked: User.setPicture(Wallpaper.path)
                }

                PushButton {
                    text: "Choose…"
                    primary: true
                    enabled: User.canPick
                    onClicked: User.pickPicture()
                }
            }
        }
    }
}
