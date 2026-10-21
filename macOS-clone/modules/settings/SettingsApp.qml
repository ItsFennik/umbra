import QtQuick
import Quickshell
import Quickshell.Io
import qs.components
import qs.config
import qs.services

// Umbra Settings, a regular window laid out like macOS System Settings.
//   qs -p <umbra dir> ipc call settings toggle
//   qs -p <umbra dir> ipc call settings page dock
Scope {
    IpcHandler {
        target: "settings"

        function toggle(): void { Settings.windowOpen = !Settings.windowOpen; }
        function open(): void { Settings.windowOpen = true; }
        function close(): void { Settings.windowOpen = false; }
        function page(name: string): void { Settings.openPage(name); }
    }

    LazyLoader {
        active: Settings.windowOpen

        FloatingWindow {
            id: window

            readonly property var pages: [
                { id: "appearance", text: "Appearance", icon: "contrast", tint: "#3a3a3c", keywords: "dark light mode colors matugen accent" },
                { id: "wallpaper", text: "Wallpaper", icon: "image", tint: "#32ade6", keywords: "background picture" },
                { id: "dock", text: "Desktop & Dock", icon: "monitor", tint: "#636366", keywords: "size magnification zoom hide effects animation indicators" },
                { id: "icons", text: "Icons", icon: "shapes", tint: "#ff9f0a", keywords: "icon theme whitesur" },
                { id: "cursors", text: "Cursors", icon: "cursor", tint: "#bf5af2", keywords: "pointer mouse size" }
            ]
            readonly property var current: Settings.page === "user" ? { text: User.name } : pages.find(p => p.id === Settings.page) ?? pages[0]

            title: "Umbra Settings"
            implicitWidth: 780
            implicitHeight: 560
            minimumSize: Qt.size(640, 420)
            color: Qt.alpha(Theme.popupBackground, 1)
            onVisibleChanged: if (!visible) Settings.windowOpen = false

            Rectangle {
                id: sidebar
                anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
                width: 220
                color: Theme.moduleBackground

                Rectangle {
                    anchors { right: parent.right; top: parent.top; bottom: parent.bottom }
                    width: 1
                    color: Theme.hairline
                }

                Column {
                    anchors { left: parent.left; right: parent.right; top: parent.top; margins: 10; topMargin: 14 }
                    spacing: 10

                    // Search field filters the sidebar by title and keywords.
                    Rectangle {
                        width: parent.width
                        height: 28
                        radius: Theme.radiusSmall
                        color: Theme.tileOff

                        Icon {
                            id: glass
                            anchors { left: parent.left; leftMargin: 8; verticalCenter: parent.verticalCenter }
                            name: "search"
                            size: 13
                            color: Theme.textSecondary
                        }

                        TextInput {
                            id: search
                            anchors { left: glass.right; leftMargin: 6; right: parent.right; rightMargin: 8; verticalCenter: parent.verticalCenter }
                            color: Theme.text
                            selectionColor: Theme.accent
                            selectedTextColor: Theme.onAccent
                            clip: true
                            font { family: Theme.font; pixelSize: 13 }

                            Text {
                                visible: search.text === ""
                                text: "Search"
                                color: Theme.textSecondary
                                font: search.font
                            }
                        }
                    }

                    SidebarItem {
                        width: parent.width
                        height: 52
                        text: User.name
                        detail: "Profile Picture"
                        current: Settings.page === "user"
                        onClicked: Settings.page = "user"

                        Avatar { size: 36 }
                    }

                    Column {
                        width: parent.width
                        spacing: 1

                        Repeater {
                            model: window.pages.filter(p => {
                                const q = search.text.trim().toLowerCase();
                                return q === "" || (p.text + " " + p.keywords).toLowerCase().includes(q);
                            })

                            delegate: SidebarItem {
                                required property var modelData

                                width: parent.width
                                text: modelData.text
                                current: Settings.page === modelData.id
                                onClicked: Settings.page = modelData.id

                                Rectangle {
                                    width: 22
                                    height: 22
                                    radius: 6
                                    color: modelData.tint

                                    Icon {
                                        anchors.centerIn: parent
                                        name: modelData.icon
                                        size: 13
                                        color: "white"
                                    }
                                }
                            }
                        }
                    }
                }
            }

            Item {
                anchors { left: sidebar.right; right: parent.right; top: parent.top; bottom: parent.bottom }

                Text {
                    id: heading
                    anchors { left: parent.left; top: parent.top; leftMargin: 28; topMargin: 18 }
                    text: window.current.text
                    color: Theme.text
                    font { family: Theme.font; pixelSize: 15; weight: Font.Bold }
                }

                Rectangle {
                    id: headerLine
                    anchors { left: parent.left; right: parent.right; top: heading.bottom; topMargin: 14 }
                    height: 1
                    color: Theme.hairline
                    opacity: scroller.contentY > 0 ? 1 : 0
                }

                Flickable {
                    id: scroller
                    anchors { left: parent.left; right: parent.right; top: headerLine.bottom; bottom: parent.bottom }
                    contentHeight: page.height + 40
                    boundsBehavior: Flickable.StopAtBounds
                    clip: true

                    Loader {
                        id: page
                        x: 28
                        y: 16
                        width: scroller.width - 56
                        source: ({
                            user: "UserPage.qml",
                            appearance: "AppearancePage.qml",
                            wallpaper: "WallpaperPage.qml",
                            dock: "DockPage.qml",
                            icons: "IconsPage.qml",
                            cursors: "CursorsPage.qml"
                        })[Settings.page] ?? "AppearancePage.qml"
                        onLoaded: scroller.contentY = 0
                    }
                }
            }
        }
    }
}
