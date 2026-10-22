import QtQuick

// A text button in the Orbital lock screen's top-right row: slides left and shows a ✦ on hover.
Item {
    id: root

    property string label: ""
    property real s: 1
    property string fontFamily: ""
    property color mainText: "white"
    property color dimText: "#666666"

    signal clicked()

    width: text.width + 20 * s
    height: 15 * s

    Text {
        id: text
        anchors { right: parent.right; rightMargin: area.containsMouse ? 15 * root.s : 0 }
        text: root.label.toUpperCase()
        color: area.containsMouse ? root.mainText : root.dimText
        font { family: root.fontFamily; pixelSize: 10 * root.s; letterSpacing: 3 * root.s }
        Behavior on color { ColorAnimation { duration: 200 } }
        Behavior on anchors.rightMargin { NumberAnimation { duration: 200 } }
    }

    Text {
        anchors { left: text.right; leftMargin: 4 * root.s; verticalCenter: text.verticalCenter }
        text: "✦"
        color: root.mainText
        opacity: area.containsMouse ? 1 : 0
        font.pixelSize: 8 * root.s
        Behavior on opacity { NumberAnimation { duration: 200 } }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
