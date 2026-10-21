import QtQuick
import qs.config

// Menu bar item with the macOS hover/pressed highlight.
MouseArea {
    id: root

    property bool active: false
    default property alias content: row.data

    implicitWidth: row.implicitWidth + 14
    implicitHeight: Theme.barHeight - 6
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor

    Rectangle {
        anchors.fill: parent
        radius: 5
        color: root.active || root.pressed ? Theme.hover : root.containsMouse ? Qt.alpha(Theme.hover, 0.6) : "transparent"
        Behavior on color { ColorAnimation { duration: Theme.durationShort } }
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 6
    }
}
