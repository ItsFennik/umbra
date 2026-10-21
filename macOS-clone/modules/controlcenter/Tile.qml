import QtQuick
import qs.components
import qs.config

// Small square-ish module with one toggle, e.g. Do Not Disturb.
MouseArea {
    id: root

    property string icon
    property string title
    property bool checked: false

    implicitHeight: 64
    cursorShape: Qt.PointingHandCursor

    Rectangle {
        anchors.fill: parent
        radius: Theme.radiusMedium
        color: Theme.moduleBackground
        border { width: 1; color: Theme.hairline }
    }

    Rectangle {
        id: circle
        anchors { left: parent.left; leftMargin: 10; top: parent.top; topMargin: 9 }
        width: 26
        height: 26
        radius: width / 2
        color: root.checked ? Theme.accent : Theme.tileOff
        Behavior on color { ColorAnimation { duration: Theme.durationShort } }

        Icon {
            anchors.centerIn: parent
            name: root.icon
            size: 14
            color: root.checked ? Theme.onAccent : Theme.text
        }
    }

    Text {
        anchors { left: parent.left; leftMargin: 10; right: parent.right; rightMargin: 8; bottom: parent.bottom; bottomMargin: 8 }
        text: root.title
        elide: Text.ElideRight
        color: Theme.text
        font { family: Theme.font; pixelSize: 12; weight: Font.DemiBold }
    }
}
