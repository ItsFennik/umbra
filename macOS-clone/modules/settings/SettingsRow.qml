import QtQuick
import qs.config

// Row in a SettingsGroup: title and subtitle on the left, a control on the right.
// Rows after the first draw a hairline above themselves.
MouseArea {
    id: root

    property string title
    property string subtitle
    property bool selected: false
    property int leftPadding: 12
    default property alias trailing: slot.data

    width: parent.width
    implicitHeight: Math.max(subtitle !== "" ? 50 : 40, slot.childrenRect.height + 16)
    opacity: enabled ? 1 : 0.45

    Rectangle {
        visible: root.y > 0
        anchors { left: parent.left; right: parent.right; top: parent.top; leftMargin: root.leftPadding; rightMargin: 12 }
        height: 1
        color: Theme.hairline
    }

    Column {
        anchors { left: parent.left; leftMargin: root.leftPadding; right: slot.left; rightMargin: 12; verticalCenter: parent.verticalCenter }
        spacing: 2

        Text {
            width: parent.width
            text: root.title
            elide: Text.ElideRight
            color: Theme.text
            font { family: Theme.font; weight: Theme.fontWeight; pixelSize: Theme.px(13) }
        }

        Text {
            width: parent.width
            visible: root.subtitle !== ""
            text: root.subtitle
            wrapMode: Text.WordWrap
            maximumLineCount: 2
            elide: Text.ElideRight
            color: Theme.textSecondary
            font { family: Theme.font; weight: Theme.fontWeight; pixelSize: Theme.px(11) }
        }
    }

    Item {
        id: slot
        anchors { right: parent.right; rightMargin: 12; verticalCenter: parent.verticalCenter }
        width: childrenRect.width
        height: childrenRect.height
    }
}
