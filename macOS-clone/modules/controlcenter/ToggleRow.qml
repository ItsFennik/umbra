import QtQuick
import qs.components
import qs.config

// Circular toggle with a title and status line. The toggle and the label are
// separate targets: the circle switches the feature, the label opens details.
Item {
    id: root

    property string icon
    property string title
    property string subtitle
    property bool checked: false
    property bool available: true
    property bool hasDetails: false

    signal toggled()
    signal detailsRequested()

    implicitHeight: 32
    opacity: available ? 1 : 0.45

    MouseArea {
        id: circle
        width: 28
        height: 28
        anchors.verticalCenter: parent.verticalCenter
        enabled: root.available
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggled()

        Rectangle {
            anchors.fill: parent
            radius: width / 2
            color: root.checked ? Theme.accent : Theme.tileOff
            Behavior on color { ColorAnimation { duration: Theme.durationShort } }
        }

        Icon {
            anchors.centerIn: parent
            name: root.icon
            size: 15
            color: root.checked ? Theme.onAccent : Theme.text
        }
    }

    MouseArea {
        id: label
        anchors { left: circle.right; leftMargin: 8; right: parent.right; top: parent.top; bottom: parent.bottom }
        enabled: root.available && root.hasDetails
        hoverEnabled: true
        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: root.detailsRequested()

        Column {
            anchors { left: parent.left; right: chevron.left; verticalCenter: parent.verticalCenter }

            Text {
                width: parent.width
                text: root.title
                elide: Text.ElideRight
                color: Theme.text
                font { family: Theme.font; pixelSize: 13; weight: Font.DemiBold }
            }

            Text {
                width: parent.width
                text: root.subtitle
                elide: Text.ElideRight
                color: Theme.textSecondary
                font { family: Theme.font; pixelSize: 11 }
            }
        }

        Icon {
            id: chevron
            anchors { right: parent.right; verticalCenter: parent.verticalCenter }
            visible: root.hasDetails
            name: "chevron-right"
            size: 12
            color: label.containsMouse ? Theme.text : Theme.textSecondary
        }
    }
}
