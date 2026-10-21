import QtQuick
import qs.config

// Small rounded System Settings button.
MouseArea {
    id: root

    property string text
    property bool primary: false

    implicitWidth: label.implicitWidth + 24
    implicitHeight: 24
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    opacity: enabled ? 1 : 0.45

    Rectangle {
        anchors.fill: parent
        radius: Theme.radiusSmall
        color: root.primary ? Theme.accent : root.pressed ? Theme.hover : Theme.tileOff
        border { width: root.primary ? 0 : 1; color: Theme.hairline }
    }

    Text {
        id: label
        anchors.centerIn: parent
        text: root.text
        color: root.primary ? Theme.onAccent : Theme.text
        font { family: Theme.font; pixelSize: 12 }
    }
}
