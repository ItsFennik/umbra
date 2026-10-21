import QtQuick
import qs.config

// Settings sidebar entry: a leading badge (the default child), a title and an optional detail line.
MouseArea {
    id: root

    property string text
    property string detail
    property bool current: false
    default property alias badge: badgeSlot.data

    implicitHeight: 30
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor

    Rectangle {
        anchors.fill: parent
        radius: Theme.radiusSmall
        color: root.current ? Theme.accent : root.containsMouse ? Theme.hover : "transparent"
    }

    Item {
        id: badgeSlot
        anchors { left: parent.left; leftMargin: 6; verticalCenter: parent.verticalCenter }
        width: childrenRect.width
        height: childrenRect.height
    }

    Column {
        anchors { left: badgeSlot.right; leftMargin: 9; right: parent.right; rightMargin: 6; verticalCenter: parent.verticalCenter }

        Text {
            width: parent.width
            text: root.text
            elide: Text.ElideRight
            color: root.current ? Theme.onAccent : Theme.text
            font { family: Theme.font; pixelSize: Theme.px(13); weight: Theme.weight(root.detail !== "" ? Font.DemiBold : Font.Normal) }
        }

        Text {
            width: parent.width
            visible: root.detail !== ""
            text: root.detail
            elide: Text.ElideRight
            color: root.current ? Qt.alpha(Theme.onAccent, 0.75) : Theme.textSecondary
            font { family: Theme.font; weight: Theme.fontWeight; pixelSize: Theme.px(11) }
        }
    }
}
