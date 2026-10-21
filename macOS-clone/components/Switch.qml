import QtQuick
import qs.config

MouseArea {
    id: root

    property bool checked: false
    signal toggled(bool checked)

    implicitWidth: 32
    implicitHeight: 18
    cursorShape: Qt.PointingHandCursor
    onClicked: toggled(!checked)

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: root.checked ? Theme.accent : Theme.tileOff
        Behavior on color { ColorAnimation { duration: Theme.durationShort } }

        Rectangle {
            x: root.checked ? parent.width - width - 2 : 2
            anchors.verticalCenter: parent.verticalCenter
            width: parent.height - 4
            height: width
            radius: width / 2
            color: "white"
            Behavior on x { NumberAnimation { duration: Theme.durationShort; easing.type: Theme.easing } }
        }
    }
}
