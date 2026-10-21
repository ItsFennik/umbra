import QtQuick
import qs.config

// A grouped section of Control Center.
Rectangle {
    default property alias content: column.data
    property alias spacing: column.spacing
    property int padding: 10

    implicitHeight: column.implicitHeight + padding * 2
    radius: Theme.radiusMedium
    color: Theme.moduleBackground
    border { width: 1; color: Theme.hairline }

    Column {
        id: column
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: parent.padding }
        spacing: 8
    }
}
