import QtQuick
import qs.config

// Rounded inset group of rows, like a System Settings section, with an optional caption above.
Column {
    id: root

    property string title
    property string footer
    default property alias content: rows.data

    width: parent.width
    spacing: 6

    Text {
        visible: root.title !== ""
        leftPadding: 4
        text: root.title
        color: Theme.text
        font { family: Theme.font; pixelSize: Theme.px(13); weight: Theme.weight(Font.DemiBold) }
    }

    Rectangle {
        width: parent.width
        height: rows.implicitHeight
        radius: Theme.radiusMedium
        color: Theme.moduleBackground
        border { width: 1; color: Theme.hairline }

        Column {
            id: rows
            anchors { left: parent.left; right: parent.right; top: parent.top }
        }
    }

    Text {
        visible: root.footer !== ""
        width: parent.width
        leftPadding: 4
        rightPadding: 4
        text: root.footer
        wrapMode: Text.WordWrap
        color: Theme.textSecondary
        font { family: Theme.font; weight: Theme.fontWeight; pixelSize: Theme.px(11) }
    }
}
