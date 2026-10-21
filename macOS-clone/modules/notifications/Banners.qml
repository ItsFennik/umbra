import QtQuick
import Quickshell
import Quickshell.Services.Notifications
import Quickshell.Wayland
import qs.config
import qs.services

// Transient banners in the top-right corner. They leave the screen after a
// timeout but stay in Notification Center until dismissed.
PanelWindow {
    id: window

    screen: Compositor.focusedScreen ?? Quickshell.screens[0]
    visible: Notifications.banners.length > 0 && Panels.current !== "notifications"

    anchors { top: true; right: true }
    margins { top: Theme.panelGap; right: Theme.panelGap }
    implicitWidth: 360
    implicitHeight: Math.max(1, column.implicitHeight)
    color: "transparent"

    WlrLayershell.namespace: "umbra-notifications"
    WlrLayershell.layer: WlrLayer.Overlay
    BackgroundEffect.blurRegion: Region { item: Theme.blur ? column : null }
    mask: Region { item: column }

    Column {
        id: column
        width: parent.width
        spacing: 8

        Repeater {
            model: ScriptModel { values: Notifications.banners.slice(0, 4) }

            delegate: NotificationCard {
                id: card
                required property var modelData

                notification: modelData
                width: column.width
                background: Theme.popupBackground

                // Slide in from the right.
                transform: Translate { id: slide; x: 380 }
                Component.onCompleted: enter.start()
                NumberAnimation { id: enter; target: slide; property: "x"; to: 0; duration: Theme.durationMedium; easing.type: Theme.easing }

                Timer {
                    interval: card.notification.expireTimeout > 0 ? card.notification.expireTimeout : 5000
                    running: card.notification.urgency !== NotificationUrgency.Critical && !card.containsMouse
                    onTriggered: Notifications.hideBanner(card.notification)
                }
            }
        }
    }
}
