import QtQuick
import qs.config

// Single-line System Settings text field with a placeholder.
Rectangle {
    id: root

    property alias text: input.text
    property alias input: input
    property string placeholder
    signal accepted()

    implicitWidth: 200
    implicitHeight: 24
    radius: Theme.radiusSmall
    color: Theme.tileOff
    border { width: 1; color: input.activeFocus ? Theme.accent : Theme.hairline }

    TextInput {
        id: input
        anchors { fill: parent; leftMargin: 8; rightMargin: 8 }
        verticalAlignment: TextInput.AlignVCenter
        clip: true
        color: Theme.text
        selectionColor: Theme.accent
        selectedTextColor: Theme.onAccent
        font { family: Theme.font; weight: Theme.fontWeight; pixelSize: Theme.px(12) }
        onAccepted: root.accepted()

        Text {
            anchors.verticalCenter: parent.verticalCenter
            visible: input.text === ""
            text: root.placeholder
            color: Theme.textSecondary
            font: input.font
        }
    }
}
