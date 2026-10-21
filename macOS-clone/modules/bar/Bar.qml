import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.components
import qs.config
import qs.services

PanelWindow {
    id: bar

    required property ShellScreen modelData
    screen: modelData

    anchors {
        top: true
        left: true
        right: true
    }
    implicitHeight: Theme.barHeight
    color: "transparent"

    WlrLayershell.namespace: "umbra-bar"
    WlrLayershell.layer: WlrLayer.Top
    BackgroundEffect.blurRegion: Region { item: background }

    Rectangle {
        id: background
        anchors.fill: parent
        color: Theme.barBackground
        Behavior on color { ColorAnimation { duration: Theme.durationMedium } }

        Rectangle {
            anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
            height: 1
            color: Theme.hairline
        }
    }

    Row {
        anchors { left: parent.left; leftMargin: 7; verticalCenter: parent.verticalCenter }
        spacing: 16

        BarButton {
            id: logo
            anchors.verticalCenter: parent.verticalCenter
            // Only the logo opens plain item menus from the bar.
            active: Panels.current === "menu" && ContextMenu.handle === null && ContextMenu.edge === "top"
            onClicked: active ? Panels.close() : ContextMenu.open([
                { text: "Umbra Settings…", action: () => Settings.windowOpen = true },
                { text: "Wallpaper…", action: () => Panels.open("wallpaper", bar.screen) },
                { separator: true },
                { text: "Reload Umbra", action: () => Quickshell.reload(false) }
            ], bar.screen, logo.mapToItem(null, 0, 0).x)
            Logo {}
        }

        ActiveApp { anchors.verticalCenter: parent.verticalCenter }
        Workspaces {
            anchors.verticalCenter: parent.verticalCenter
            screen: bar.screen
        }
    }

    Row {
        anchors { right: parent.right; rightMargin: 8; verticalCenter: parent.verticalCenter }
        spacing: 2

        Tray {
            anchors.verticalCenter: parent.verticalCenter
            window: bar
        }

        BarButton {
            anchors.verticalCenter: parent.verticalCenter
            visible: Battery.available
            onClicked: Panels.toggle("controlcenter", bar.screen)
            BatteryIndicator {}
        }

        BarButton {
            anchors.verticalCenter: parent.verticalCenter
            visible: NetworkService.available
            onClicked: Panels.toggle("controlcenter", bar.screen)
            Icon { name: NetworkService.icon; size: 15 }
        }

        BarButton {
            anchors.verticalCenter: parent.verticalCenter
            visible: Audio.available
            onClicked: Panels.toggle("controlcenter", bar.screen)
            onWheel: event => Audio.setVolume(Audio.volume + (event.angleDelta.y > 0 ? 0.05 : -0.05))
            Icon { name: Audio.icon; size: 15 }
        }

        BarButton {
            anchors.verticalCenter: parent.verticalCenter
            active: Panels.current === "controlcenter"
            onClicked: Panels.toggle("controlcenter", bar.screen)
            Icon { name: "toggles"; size: 15 }
        }

        BarButton {
            anchors.verticalCenter: parent.verticalCenter
            active: Panels.current === "notifications"
            onClicked: Panels.toggle("notifications", bar.screen)
            Clock {}
        }
    }
}
