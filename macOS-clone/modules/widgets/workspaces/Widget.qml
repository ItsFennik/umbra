import QtQuick
import qs.config
import qs.services
import qs.modules.widgets

// Workspace tiles from ext-workspace-v1. Window counts need a compositor adapter (Hyprland today).
WidgetBase {
    id: root

    readonly property bool counts: (options.showWindows ?? true) && Compositor.windowWorkspacesAvailable
    readonly property var workspaces: {
        const all = Compositor.workspacesFor(screen);
        return options.hideEmpty && Compositor.windowWorkspacesAvailable ? all.filter(w => w.active || windowCount(w) > 0) : all;
    }

    function windowCount(workspace) {
        return Compositor.windows.filter(w => Compositor.workspaceNameOf(w) === workspace.name).length;
    }

    WidgetCard {}

    Text {
        anchors.centerIn: parent
        visible: root.workspaces.length === 0
        text: Compositor.workspacesAvailable ? "No workspaces" : "Workspaces unavailable"
        color: Theme.textSecondary
        font { family: Theme.font; weight: Theme.fontWeight; pixelSize: Theme.px(12) }
    }

    Row {
        id: tiles
        anchors { fill: parent; margins: 12 }
        spacing: 8

        readonly property real tileWidth: root.workspaces.length > 0 ? Math.min(height * 1.4, (width - spacing * (root.workspaces.length - 1)) / root.workspaces.length) : 0

        Repeater {
            model: root.workspaces

            delegate: MouseArea {
                id: tile
                required property var modelData
                readonly property int windows: root.counts ? root.windowCount(modelData) : 0

                width: tiles.tileWidth
                height: tiles.height
                hoverEnabled: true
                enabled: modelData.canActivate
                cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                onClicked: modelData.activate()

                Rectangle {
                    anchors.fill: parent
                    radius: 12
                    color: tile.modelData.active ? Theme.accent : tile.containsMouse ? Theme.hover : Theme.tileOff
                    border { width: tile.modelData.urgent ? 2 : 0; color: Theme.destructive }
                    Behavior on color { ColorAnimation { duration: Theme.durationShort } }
                }

                Text {
                    anchors { centerIn: parent; verticalCenterOffset: root.counts ? -5 : 0 }
                    text: tile.modelData.name
                    color: tile.modelData.active ? Theme.onAccent : Theme.text
                    font { family: Theme.font; pixelSize: Theme.px(15); weight: Theme.weight(Font.DemiBold); features: { "tnum": 1 } }
                }

                Row {
                    anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 9 }
                    visible: root.counts
                    spacing: 3

                    Repeater {
                        model: Math.min(5, tile.windows)

                        delegate: Rectangle {
                            width: 4
                            height: 4
                            radius: 2
                            color: tile.modelData.active ? Theme.onAccent : Theme.textSecondary
                        }
                    }
                }
            }
        }
    }
}
