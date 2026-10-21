import QtQuick
import qs.components
import qs.config

// Header with a back button, title and optional switch, followed by content.
Column {
    id: root

    property string title
    property bool hasSwitch: false
    property bool checked: false
    default property alias content: body.data

    signal back()
    signal toggled(bool checked)

    spacing: 8

    Item {
        width: parent.width
        height: 28

        MouseArea {
            id: backButton
            anchors { left: parent.left; verticalCenter: parent.verticalCenter }
            width: 24
            height: 24
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.back()

            Rectangle {
                anchors.fill: parent
                radius: 12
                color: backButton.containsMouse ? Theme.hover : "transparent"
            }

            Icon {
                anchors.centerIn: parent
                name: "chevron-left"
                size: 14
            }
        }

        Text {
            anchors { left: backButton.right; leftMargin: 6; verticalCenter: parent.verticalCenter }
            text: root.title
            color: Theme.text
            font { family: Theme.font; pixelSize: 14; weight: Font.DemiBold }
        }

        Switch {
            anchors { right: parent.right; verticalCenter: parent.verticalCenter }
            visible: root.hasSwitch
            checked: root.checked
            onToggled: on => root.toggled(on)
        }
    }

    Rectangle {
        width: parent.width
        height: 1
        color: Theme.hairline
    }

    Column {
        id: body
        width: parent.width
        spacing: 2
    }
}
