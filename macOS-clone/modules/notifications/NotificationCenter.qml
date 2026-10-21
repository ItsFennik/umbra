import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.components
import qs.config
import qs.services

// Notification history, opened from the menu bar clock.
// Toggle with: qs -p <umbra dir> ipc call notifications toggle
Scope {
    IpcHandler {
        target: "notifications"

        function toggle(): void { Panels.toggle("notifications"); }
        function open(): void { Panels.open("notifications"); }
        function close(): void { Panels.close(); }
        function clear(): void { Notifications.clearAll(); }
    }

    LazyLoader {
        active: Panels.current === "notifications"

        PopupSurface {
            panelName: "notificationcenter"
            BackgroundEffect.blurRegion: Region { item: Theme.blur ? panel : null }

            SystemClock {
                id: clock
                precision: SystemClock.Minutes
            }

            Rectangle {
                id: panel

                anchors { top: parent.top; right: parent.right; bottom: parent.bottom; margins: Theme.panelGap }
                width: 360
                radius: Theme.radiusLarge
                color: Theme.popupBackground
                border { width: 1; color: Theme.dockBorder }
                clip: true

                transform: Translate { id: slide; x: 40 }
                opacity: 0
                Component.onCompleted: { opacity = 1; slide.x = 0; }
                Behavior on opacity { NumberAnimation { duration: Theme.durationShort } }

                MouseArea { anchors.fill: parent }

                Item {
                    id: header
                    anchors { left: parent.left; right: parent.right; top: parent.top; margins: 14 }
                    height: 40

                    Column {
                        anchors.verticalCenter: parent.verticalCenter

                        Text {
                            text: Qt.formatDate(clock.date, "dddd d MMMM")
                            color: Theme.textSecondary
                            font { family: Theme.font; pixelSize: Theme.px(11); weight: Theme.weight(Font.Medium) }
                        }

                        Text {
                            text: "Notifications"
                            color: Theme.text
                            font { family: Theme.font; pixelSize: Theme.px(16); weight: Theme.weight(Font.DemiBold) }
                        }
                    }

                    MouseArea {
                        id: clear
                        anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                        width: clearText.implicitWidth + 16
                        height: 24
                        visible: Notifications.history.length > 0
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Notifications.clearAll()

                        Rectangle {
                            anchors.fill: parent
                            radius: 12
                            color: clear.containsMouse ? Theme.hover : Theme.tileOff
                        }

                        Text {
                            id: clearText
                            anchors.centerIn: parent
                            text: "Clear All"
                            color: Theme.text
                            font { family: Theme.font; pixelSize: Theme.px(11); weight: Theme.weight(Font.Medium) }
                        }
                    }
                }

                Text {
                    anchors { left: parent.left; right: parent.right; top: header.bottom; topMargin: 4; leftMargin: 14 }
                    visible: Notifications.doNotDisturb
                    text: "Focus is on — banners are silenced."
                    color: Theme.textSecondary
                    font { family: Theme.font; weight: Theme.fontWeight; pixelSize: Theme.px(11) }
                }

                Column {
                    anchors.centerIn: parent
                    visible: Notifications.history.length === 0
                    spacing: 8

                    Icon {
                        anchors.horizontalCenter: parent.horizontalCenter
                        name: "bell"
                        size: 28
                        strokeWidth: 1.5
                        color: Theme.textSecondary
                    }

                    Text {
                        text: "No Notifications"
                        color: Theme.textSecondary
                        font { family: Theme.font; weight: Theme.fontWeight; pixelSize: Theme.px(13) }
                    }
                }

                ListView {
                    anchors { left: parent.left; right: parent.right; top: header.bottom; bottom: parent.bottom; margins: 10; topMargin: Notifications.doNotDisturb ? 24 : 8 }
                    clip: true
                    spacing: 8
                    boundsBehavior: Flickable.StopAtBounds
                    model: ScriptModel { values: Notifications.history }

                    delegate: NotificationCard {
                        required property var modelData
                        notification: modelData
                        width: ListView.view.width
                        now: clock.date
                    }

                    add: Transition { NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Theme.durationMedium } }
                    remove: Transition { NumberAnimation { property: "opacity"; to: 0; duration: Theme.durationShort } }
                    displaced: Transition { NumberAnimation { property: "y"; duration: Theme.durationMedium; easing.type: Theme.easing } }
                }
            }
        }
    }
}
