import QtQuick
import qs.config

// Row of small choice buttons, the current one in the accent color.
// options: [{ value, text }]; emits picked(value).
Row {
    id: root

    property var options: []
    property var value
    signal picked(var value)

    spacing: 4

    Repeater {
        model: root.options

        delegate: MouseArea {
            id: option
            required property var modelData
            readonly property bool current: root.value === modelData.value

            width: Math.max(44, label.implicitWidth + 20)
            height: 24
            cursorShape: Qt.PointingHandCursor
            onClicked: root.picked(modelData.value)

            Rectangle {
                anchors.fill: parent
                radius: Theme.radiusSmall
                color: option.current ? Theme.accent : Theme.tileOff
            }

            Text {
                id: label
                anchors.centerIn: parent
                text: option.modelData.text
                color: option.current ? Theme.onAccent : Theme.text
                font { family: Theme.font; weight: Theme.fontWeight; pixelSize: Theme.px(12) }
            }
        }
    }
}
