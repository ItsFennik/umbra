import QtQuick
import Qt.labs.folderlistmodel
import Quickshell
import Quickshell.Wayland
import qs.components
import qs.config
import qs.services

// Thumbnail grid of the images in Wallpaper.directory.
LazyLoader {
    active: Panels.current === "wallpaper"

    PopupSurface {
        panelName: "wallpaperpicker"
        BackgroundEffect.blurRegion: Region { item: Theme.blur ? panel : null }

        Rectangle {
            id: panel

            anchors.centerIn: parent
            width: Math.min(parent.width - 80, 760)
            height: Math.min(parent.height - 80, 520)
            radius: Theme.radiusLarge
            color: Theme.popupBackground
            border { width: 1; color: Theme.dockBorder }
            clip: true

            opacity: 0
            scale: 0.98
            Component.onCompleted: { opacity = 1; scale = 1; }
            Behavior on opacity { NumberAnimation { duration: Theme.durationShort } }
            Behavior on scale { NumberAnimation { duration: Theme.durationMedium; easing.type: Theme.easing } }

            MouseArea { anchors.fill: parent }

            Item {
                id: header
                anchors { left: parent.left; right: parent.right; top: parent.top; margins: 16 }
                height: 36

                Column {
                    anchors.verticalCenter: parent.verticalCenter

                    Text {
                        text: "Wallpaper"
                        color: Theme.text
                        font { family: Theme.font; pixelSize: Theme.px(16); weight: Theme.weight(Font.DemiBold) }
                    }

                    Text {
                        text: Wallpaper.directory.replace(Quickshell.env("HOME"), "~") + " · " + folder.count + " images"
                        color: Theme.textSecondary
                        font { family: Theme.font; weight: Theme.fontWeight; pixelSize: Theme.px(11) }
                    }
                }

                Row {
                    anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                    visible: Matugen.available
                    spacing: 8

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Match colors"
                        color: Theme.textSecondary
                        font { family: Theme.font; weight: Theme.fontWeight; pixelSize: Theme.px(12) }
                    }

                    Switch {
                        anchors.verticalCenter: parent.verticalCenter
                        checked: Matugen.enabled
                        onToggled: on => Matugen.setEnabled(on)
                    }
                }
            }

            FolderListModel {
                id: folder
                folder: "file://" + Wallpaper.directory
                nameFilters: ["*.jpg", "*.jpeg", "*.png", "*.webp", "*.JPG", "*.JPEG", "*.PNG", "*.WEBP"]
                showDirs: false
                sortField: FolderListModel.Name
            }

            Text {
                anchors.centerIn: parent
                visible: folder.status === FolderListModel.Ready && folder.count === 0
                text: "No images in this folder"
                color: Theme.textSecondary
                font { family: Theme.font; weight: Theme.fontWeight; pixelSize: Theme.px(13) }
            }

            GridView {
                id: grid

                readonly property int columns: Math.max(2, Math.floor(width / 180))

                anchors { left: parent.left; right: parent.right; top: header.bottom; bottom: parent.bottom; margins: 12; topMargin: 10 }
                clip: true
                cellWidth: Math.floor(width / columns)
                cellHeight: Math.round(cellWidth * 0.625)
                boundsBehavior: Flickable.StopAtBounds
                model: folder

                delegate: MouseArea {
                    id: cell
                    required property string filePath
                    required property string fileName

                    readonly property bool current: filePath === Wallpaper.path

                    width: grid.cellWidth
                    height: grid.cellHeight
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Wallpaper.set(filePath)

                    Rectangle {
                        anchors { fill: parent; margins: 4 }
                        radius: Theme.radiusMedium
                        color: Theme.tileOff
                        border { width: cell.current ? 3 : cell.containsMouse ? 2 : 0; color: cell.current ? Theme.accent : Theme.text }

                        Image {
                            anchors { fill: parent; margins: cell.current ? 4 : cell.containsMouse ? 3 : 0 }
                            source: "file://" + cell.filePath
                            sourceSize { width: 320; height: 200 }
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            smooth: true
                        }
                    }
                }
            }
        }
    }
}
