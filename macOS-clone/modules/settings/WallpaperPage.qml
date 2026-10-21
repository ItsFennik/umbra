import QtQuick
import Qt.labs.folderlistmodel
import Quickshell
import qs.config
import qs.services

Column {
    id: root
    spacing: 20

    SettingsGroup {
        SettingsRow {
            title: Wallpaper.path.split("/").pop()
            subtitle: Wallpaper.directory.replace(Quickshell.env("HOME"), "~")
            implicitHeight: 120

            Rectangle {
                width: 160
                height: 100
                radius: Theme.radiusMedium
                color: Theme.tileOff
                clip: true

                Image {
                    anchors.fill: parent
                    source: "file://" + Wallpaper.path
                    sourceSize { width: 320; height: 200 }
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                }
            }
        }
    }

    SettingsGroup {
        title: "Wallpapers"
        footer: folder.count === 0 ? "No images in " + Wallpaper.directory.replace(Quickshell.env("HOME"), "~") : ""

        Item {
            width: parent.width
            height: grid.height + 20
            visible: folder.count > 0

            Flow {
                id: grid

                readonly property int columns: Math.max(3, Math.floor(width / 120))
                readonly property real cell: (width - spacing * (columns - 1)) / columns

                anchors { left: parent.left; right: parent.right; top: parent.top; margins: 10 }
                spacing: 8

                Repeater {
                    model: FolderListModel {
                        id: folder
                        folder: "file://" + Wallpaper.directory
                        nameFilters: ["*.jpg", "*.jpeg", "*.png", "*.webp", "*.JPG", "*.JPEG", "*.PNG", "*.WEBP"]
                        showDirs: false
                        sortField: FolderListModel.Name
                    }

                    delegate: MouseArea {
                        id: cell
                        required property string filePath
                        readonly property bool current: filePath === Wallpaper.path

                        width: grid.cell
                        height: Math.round(grid.cell * 0.625)
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Wallpaper.set(filePath)

                        Rectangle {
                            anchors.fill: parent
                            radius: Theme.radiusSmall + 2
                            color: Theme.tileOff
                            border { width: cell.current ? 3 : 0; color: Theme.accent }

                            Image {
                                anchors { fill: parent; margins: cell.current ? 4 : 0 }
                                source: "file://" + cell.filePath
                                sourceSize { width: 240; height: 150 }
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                            }
                        }
                    }
                }
            }
        }
    }
}
