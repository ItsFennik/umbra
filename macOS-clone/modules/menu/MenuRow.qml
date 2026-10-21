import QtQuick
import qs.components
import qs.config

// One row of a context menu, highlighted with the accent like macOS menus.
MouseArea {
    id: root

    property string text
    property bool separator: false
    property bool checked: false
    property bool hasChildren: false
    property bool back: false

    implicitWidth: label.implicitWidth + 52
    implicitHeight: separator ? 9 : 24
    hoverEnabled: !separator
    cursorShape: enabled && !separator ? Qt.PointingHandCursor : Qt.ArrowCursor

    readonly property bool highlighted: containsMouse && enabled && !separator

    Rectangle {
        visible: root.separator
        anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter; margins: 8 }
        height: 1
        color: Theme.hairline
    }

    Rectangle {
        visible: !root.separator
        anchors.fill: parent
        radius: 5
        color: root.highlighted ? Theme.accent : "transparent"
    }

    Icon {
        anchors { left: parent.left; leftMargin: 8; verticalCenter: parent.verticalCenter }
        visible: root.checked || root.back
        name: root.back ? "chevron-left" : "check"
        size: 11
        color: root.highlighted ? Theme.onAccent : Theme.text
    }

    Text {
        id: label
        visible: !root.separator
        anchors { left: parent.left; leftMargin: 24; right: parent.right; rightMargin: 24; verticalCenter: parent.verticalCenter }
        text: root.text
        elide: Text.ElideRight
        color: root.highlighted ? Theme.onAccent : Theme.text
        opacity: root.enabled ? 1 : 0.4
        font { family: Theme.font; pixelSize: 13 }
    }

    Icon {
        anchors { right: parent.right; rightMargin: 8; verticalCenter: parent.verticalCenter }
        visible: root.hasChildren
        name: "chevron-right"
        size: 11
        color: root.highlighted ? Theme.onAccent : Theme.textSecondary
    }
}
