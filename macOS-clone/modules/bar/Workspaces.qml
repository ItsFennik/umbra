import QtQuick
import Quickshell
import qs.config
import qs.services

// Hidden entirely when the compositor exposes no workspaces.
Row {
    id: root

    property ShellScreen screen

    visible: Compositor.workspacesAvailable
    spacing: 2

    Repeater {
        model: Compositor.workspacesFor(root.screen)

        delegate: MouseArea {
            id: item
            required property var modelData

            width: 22
            height: 18
            hoverEnabled: true
            enabled: modelData.canActivate
            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: modelData.activate()

            Rectangle {
                anchors.fill: parent
                radius: 5
                color: item.containsMouse && item.enabled ? Theme.hover : "transparent"
                Behavior on color { ColorAnimation { duration: Theme.durationShort } }
            }

            Text {
                anchors.centerIn: parent
                text: item.modelData.name
                color: item.modelData.active ? Theme.text : Theme.textSecondary
                font {
                    family: Theme.font
                    pixelSize: Theme.px(12)
                    weight: Theme.weight(item.modelData.active ? Font.DemiBold : Font.Normal)
                    features: { "tnum": 1 }
                }
            }

            Rectangle {
                anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom }
                width: item.modelData.active ? 10 : 0
                height: 2
                radius: 1
                color: item.modelData.urgent ? "#ff453a" : Theme.text
                Behavior on width { NumberAnimation { duration: Theme.durationMedium; easing.type: Theme.easing } }
            }
        }
    }
}
