import QtQuick
import qs.components
import qs.config

// Row in a Control Center detail list.
MouseArea {
    id: root

    property string icon
    property string text
    property string detail
    property bool selected: false
    property string trailingIcon

    implicitHeight: 32
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor

    Rectangle {
        anchors.fill: parent
        radius: Theme.radiusSmall
        color: root.containsMouse ? Theme.hover : "transparent"
    }

    Rectangle {
        id: badge
        anchors { left: parent.left; leftMargin: 6; verticalCenter: parent.verticalCenter }
        width: 22
        height: 22
        radius: 11
        color: root.selected ? Theme.accent : Theme.tileOff

        Icon {
            anchors.centerIn: parent
            name: root.icon
            size: 12
            color: root.selected ? Theme.onAccent : Theme.text
        }
    }

    Text {
        id: label
        anchors { left: badge.right; leftMargin: 10; right: trailing.left; rightMargin: 8; verticalCenter: parent.verticalCenter }
        text: root.text + (root.detail ? "  " : "")
        elide: Text.ElideRight
        color: Theme.text
        font { family: Theme.font; pixelSize: 13 }
    }

    Text {
        anchors { right: trailing.left; rightMargin: 8; verticalCenter: parent.verticalCenter }
        visible: root.detail !== ""
        text: root.detail
        color: Theme.textSecondary
        font { family: Theme.font; pixelSize: 11 }
    }

    Icon {
        id: trailing
        anchors { right: parent.right; rightMargin: 8; verticalCenter: parent.verticalCenter }
        name: root.trailingIcon
        visible: root.trailingIcon !== ""
        width: visible ? implicitWidth : 0
        size: 12
        color: Theme.textSecondary
    }
}
