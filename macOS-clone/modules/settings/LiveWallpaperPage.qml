import QtQuick
import Qt.labs.folderlistmodel
import Quickshell
import Quickshell.Io
import qs.config
import qs.services

// Videos in Wallpaper.liveDirectory, played behind the desktop with mpvpaper.
Column {
    id: root
    spacing: 20

    readonly property string home: Quickshell.env("HOME")

    SettingsGroup {
        footer: Wallpaper.mpvpaperAvailable ? "" : "mpvpaper is not installed, so live wallpapers cannot play."

        SettingsRow {
            title: Wallpaper.live !== "" ? Wallpaper.live.split("/").pop() : "No Live Wallpaper"
            subtitle: Wallpaper.live !== "" ? "Playing with mpvpaper" : "Showing " + Wallpaper.path.split("/").pop()
            implicitHeight: 120

            Row {
                spacing: 12

                PushButton {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: Wallpaper.live !== ""
                    text: "Turn Off"
                    onClicked: Wallpaper.clearLive()
                }

                Rectangle {
                    width: 160
                    height: 100
                    radius: Theme.radiusMedium
                    color: Theme.tileOff
                    clip: true

                    Image {
                        anchors.fill: parent
                        source: Wallpaper.live !== "" ? (Wallpaper.liveFrame !== "" ? "file://" + Wallpaper.liveFrame : "") : "file://" + Wallpaper.path
                        sourceSize { width: 320; height: 200 }
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                    }
                }
            }
        }

        SettingsRow {
            title: "Folder"

            TextField {
                width: 240
                text: Wallpaper.liveDirectory.replace(root.home, "~")
                placeholder: "~/Videos/Wallpapers"
                onAccepted: if (text.trim() !== "") Wallpaper.setLiveDirectory(text.trim())
            }
        }
    }

    SettingsGroup {
        title: "Live Wallpapers"
        footer: folder.count === 0 ? "No videos in " + Wallpaper.liveDirectory.replace(root.home, "~") : ""

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
                        folder: "file://" + Wallpaper.liveDirectory
                        nameFilters: ["*.mp4", "*.mkv", "*.webm", "*.mov", "*.avi", "*.gif", "*.MP4", "*.MKV", "*.WEBM", "*.MOV", "*.AVI", "*.GIF"]
                        showDirs: false
                        sortField: FolderListModel.Name
                    }

                    delegate: MouseArea {
                        id: cell
                        required property string filePath
                        required property string fileName
                        readonly property bool current: filePath === Wallpaper.live

                        width: grid.cell
                        height: Math.round(grid.cell * 0.625)
                        cursorShape: Qt.PointingHandCursor
                        enabled: Wallpaper.mpvpaperAvailable
                        onClicked: Wallpaper.setLive(filePath)

                        Rectangle {
                            anchors.fill: parent
                            radius: Theme.radiusSmall + 2
                            color: Theme.tileOff
                            border { width: cell.current ? 3 : 0; color: Theme.accent }
                            clip: true

                            Text {
                                anchors { fill: parent; margins: 6 }
                                visible: thumb.status !== Image.Ready
                                text: cell.fileName
                                wrapMode: Text.WrapAnywhere
                                elide: Text.ElideRight
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                color: Theme.textSecondary
                                font { family: Theme.font; weight: Theme.fontWeight; pixelSize: Theme.px(10) }
                            }

                            Image {
                                id: thumb
                                anchors { fill: parent; margins: cell.current ? 4 : 0 }
                                sourceSize { width: 240; height: 150 }
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                                cache: false
                            }
                        }

                        // Thumbnails are cached in ~/.cache/umbra/live, so this is quick after the first visit.
                        Process {
                            running: true
                            command: Wallpaper.thumbnailCommand(cell.filePath)
                            onExited: code => {
                                if (code === 0)
                                    thumb.source = "file://" + Wallpaper.thumbnail(cell.filePath);
                            }
                        }
                    }
                }
            }
        }
    }
}
