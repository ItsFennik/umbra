import QtQuick
import Quickshell
import Quickshell.Services.Notifications
import Quickshell.Widgets
import qs.components
import qs.config
import qs.services

// One notification: app, age, summary, body, optional image and actions.
// Clicking runs the default action; the close button dismisses it.
MouseArea {
    id: root

    required property Notification notification
    property color background: Theme.moduleBackground
    property date now: new Date()

    // The notification object can be destroyed while its card is animating out.
    readonly property var entry: !notification ? null : notification.desktopEntry ? DesktopEntries.byId(notification.desktopEntry) : DesktopEntries.heuristicLookup(notification.appName)
    readonly property string appIcon: notification?.appIcon || entry?.icon || ""
    readonly property var actions: notification?.actions.filter(a => a.identifier !== "default") ?? []
    // Some senders pass the app icon as the image; showing it twice adds nothing.
    readonly property bool hasImage: (notification?.image ?? "") !== "" && !(appIcon !== "" && notification.image.endsWith(appIcon))

    implicitHeight: layout.implicitHeight + 20
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: if (notification) Notifications.activate(notification)

    Rectangle {
        anchors.fill: parent
        radius: Theme.radiusMedium
        color: root.background
        border { width: 1; color: root.notification?.urgency === NotificationUrgency.Critical ? Theme.destructive : Theme.hairline }
    }

    Column {
        id: layout
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 10 }
        spacing: 6

        Item {
            width: parent.width
            height: 18

            IconImage {
                id: icon
                anchors.verticalCenter: parent.verticalCenter
                implicitSize: 16
                visible: root.appIcon !== ""
                source: root.appIcon.startsWith("/") || root.appIcon.includes("://") ? root.appIcon : Quickshell.iconPath(root.appIcon, true)
                asynchronous: true
                mipmap: true
            }

            Text {
                anchors { left: icon.visible ? icon.right : parent.left; leftMargin: icon.visible ? 6 : 0; right: age.left; rightMargin: 8; verticalCenter: parent.verticalCenter }
                text: (root.entry?.name ?? root.notification?.appName ?? "").toUpperCase()
                elide: Text.ElideRight
                color: Theme.textSecondary
                font { family: Theme.font; pixelSize: Theme.px(10); weight: Theme.weight(Font.DemiBold); letterSpacing: 0.3 }
            }

            Text {
                id: age
                anchors { right: parent.right; rightMargin: closeButton.visible ? 24 : 0; verticalCenter: parent.verticalCenter }
                text: Notifications.age(root.notification, root.now)
                color: Theme.textSecondary
                font { family: Theme.font; weight: Theme.fontWeight; pixelSize: Theme.px(11) }
            }

            MouseArea {
                id: closeButton
                anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                width: 18
                height: 18
                visible: root.containsMouse
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.notification?.dismiss()

                Rectangle {
                    anchors.fill: parent
                    radius: 9
                    color: closeButton.containsMouse ? Theme.hover : Theme.tileOff
                }

                Icon {
                    anchors.centerIn: parent
                    name: "x"
                    size: 10
                    strokeWidth: 2.5
                }
            }
        }

        Item {
            width: parent.width
            height: Math.max(text.implicitHeight, root.hasImage ? image.height : 0)

            Column {
                id: text
                anchors { left: parent.left; right: image.visible ? image.left : parent.right; rightMargin: image.visible ? 10 : 0 }
                spacing: 2

                Text {
                    width: parent.width
                    text: root.notification?.summary ?? ""
                    elide: Text.ElideRight
                    color: Theme.text
                    font { family: Theme.font; pixelSize: Theme.px(13); weight: Theme.weight(Font.DemiBold) }
                }

                Text {
                    width: parent.width
                    visible: text !== ""
                    text: root.notification?.body ?? ""
                    textFormat: Text.StyledText
                    wrapMode: Text.Wrap
                    maximumLineCount: 4
                    elide: Text.ElideRight
                    color: Theme.text
                    opacity: 0.85
                    font { family: Theme.font; weight: Theme.fontWeight; pixelSize: Theme.px(12) }
                    onLinkActivated: link => Qt.openUrlExternally(link)
                }
            }

            Image {
                id: image
                anchors.right: parent.right
                width: 40
                height: 40
                visible: root.hasImage
                source: root.hasImage ? root.notification.image : ""
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                sourceSize { width: 80; height: 80 }
            }
        }

        Row {
            width: parent.width
            visible: root.actions.length > 0
            spacing: 6

            Repeater {
                model: root.actions

                delegate: MouseArea {
                    id: action
                    required property var modelData
                    width: (parent.width - (root.actions.length - 1) * 6) / root.actions.length
                    height: 26
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: modelData.invoke()

                    Rectangle {
                        anchors.fill: parent
                        radius: Theme.radiusSmall
                        color: action.containsMouse ? Theme.hover : Theme.tileOff
                    }

                    Text {
                        anchors.centerIn: parent
                        width: parent.width - 12
                        horizontalAlignment: Text.AlignHCenter
                        text: action.modelData.text
                        elide: Text.ElideRight
                        color: Theme.text
                        font { family: Theme.font; pixelSize: Theme.px(12); weight: Theme.weight(Font.Medium) }
                    }
                }
            }
        }
    }
}
