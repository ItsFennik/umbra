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
    BackgroundEffect.blurRegion: Region { item: Theme.blur ? background : null }

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

    // Items come from Settings > Menu Bar (BarItems.layout), each zone built from the parts below.
    readonly property var parts: ({
        logo: logoPart,
        activeApp: activeAppPart,
        workspaces: workspacesPart,
        nowPlaying: nowPlayingPart,
        mediaControls: mediaControlsPart,
        tray: trayPart,
        battery: batteryPart,
        network: networkPart,
        volume: volumePart,
        controlCenter: controlCenterPart,
        clock: clockPart,
        power: powerPart
    })

    BarZone {
        anchors { left: parent.left; leftMargin: 7; verticalCenter: parent.verticalCenter }
        zone: "left"
        parts: bar.parts
    }

    BarZone {
        anchors { horizontalCenter: parent.horizontalCenter; verticalCenter: parent.verticalCenter }
        zone: "center"
        parts: bar.parts
    }

    BarZone {
        anchors { right: parent.right; rightMargin: 8; verticalCenter: parent.verticalCenter }
        zone: "right"
        parts: bar.parts
    }

    Component {
        id: logoPart

        BarButton {
            id: logo
            // Only the logo opens plain item menus from the bar.
            active: Panels.current === "menu" && ContextMenu.handle === null && ContextMenu.edge === "top"
            onClicked: active ? Panels.close() : ContextMenu.open([
                { text: "Umbra Settings…", action: () => Settings.windowOpen = true },
                { text: "Wallpaper…", action: () => Panels.open("wallpaper", bar.screen) },
                { separator: true },
                { text: "Reload Umbra", action: () => Quickshell.reload(false) },
                { separator: true },
                { text: "Sleep", action: () => Session.run("sleep") },
                { text: "Restart…", action: () => Session.request("restart") },
                { text: "Shut Down…", action: () => Session.request("shutdown") },
                { separator: true },
                { text: "Lock Screen", action: () => Session.run("lock") },
                { text: "Log Out " + User.name + "…", action: () => Session.request("logout") }
            ], bar.screen, logo.mapToItem(null, 0, 0).x)
            Logo {}
        }
    }

    // Text items get the same side padding as buttons.
    Component {
        id: activeAppPart

        Item {
            visible: app.visible
            implicitWidth: app.implicitWidth + 14
            implicitHeight: app.implicitHeight
            ActiveApp { id: app; anchors.centerIn: parent }
        }
    }

    Component {
        id: workspacesPart

        Item {
            visible: spaces.visible
            implicitWidth: spaces.implicitWidth + 14
            implicitHeight: spaces.implicitHeight
            Workspaces { id: spaces; anchors.centerIn: parent; screen: bar.screen }
        }
    }

    Component {
        id: nowPlayingPart
        NowPlaying { screen: bar.screen }
    }

    Component {
        id: mediaControlsPart
        MediaControls {}
    }

    Component {
        id: trayPart
        Tray { window: bar }
    }

    Component {
        id: batteryPart

        BarButton {
            visible: Battery.available
            onClicked: Panels.toggle("controlcenter", bar.screen)
            BatteryIndicator {}
        }
    }

    Component {
        id: networkPart

        BarButton {
            visible: NetworkService.available
            onClicked: Panels.toggle("controlcenter", bar.screen)
            Icon { name: NetworkService.icon; size: 15 }
        }
    }

    Component {
        id: volumePart

        BarButton {
            visible: Audio.available
            onClicked: Panels.toggle("controlcenter", bar.screen)
            onWheel: event => Audio.setVolume(Audio.volume + (event.angleDelta.y > 0 ? 0.05 : -0.05))
            Icon { name: Audio.icon; size: 15 }
        }
    }

    Component {
        id: controlCenterPart

        BarButton {
            active: Panels.current === "controlcenter"
            onClicked: Panels.toggle("controlcenter", bar.screen)
            Icon { name: "toggles"; size: 15 }
        }
    }

    Component {
        id: clockPart

        BarButton {
            active: Panels.current === "notifications"
            onClicked: Panels.toggle("notifications", bar.screen)
            Clock {}
        }
    }

    Component {
        id: powerPart

        BarButton {
            active: Panels.current === "power"
            onClicked: active ? Panels.close() : Session.request("", bar.screen)
            Icon { name: "power"; size: 15 }
        }
    }
}
