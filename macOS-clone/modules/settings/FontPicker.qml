import QtQuick
import qs.components
import qs.config

// Searchable list of installed font families, each drawn in itself. The first row is Automatic ("").
// Emits picked(family) on click and previewed(family) while hovering ("" when the pointer leaves).
Item {
    id: root

    property string value
    property var families: Theme.installedFonts
    property string automaticText: "Automatic"
    signal picked(string family)
    signal previewed(string family)

    readonly property var shown: {
        const q = search.text.trim().toLowerCase();
        return [""].concat(families.filter(f => q === "" || f.toLowerCase().includes(q)));
    }

    width: parent.width
    implicitHeight: column.implicitHeight + 20

    Column {
        id: column
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 10 }
        spacing: 8

        TextField {
            id: search
            width: parent.width
            placeholder: "Search " + root.families.length + " fonts"
        }

        Rectangle {
            width: parent.width
            height: 196
            radius: Theme.radiusSmall
            color: Theme.tileOff
            clip: true

            ListView {
                id: list
                anchors { fill: parent; margins: 4 }
                model: root.shown
                boundsBehavior: Flickable.StopAtBounds
                // Only rows near the view are created, so long font lists stay cheap.
                reuseItems: true

                delegate: MouseArea {
                    id: row
                    required property string modelData
                    readonly property bool current: modelData === root.value

                    width: list.width
                    height: 28
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onEntered: root.previewed(modelData)
                    onExited: root.previewed("")
                    onClicked: root.picked(modelData)

                    Rectangle {
                        anchors.fill: parent
                        radius: 5
                        color: row.current ? Theme.accent : row.containsMouse ? Theme.hover : "transparent"
                    }

                    // Some fonts have huge metrics; fit them to the row.
                    Text {
                        anchors { left: parent.left; leftMargin: 8; right: check.left; rightMargin: 8; top: parent.top; bottom: parent.bottom }
                        verticalAlignment: Text.AlignVCenter
                        fontSizeMode: Text.VerticalFit
                        minimumPixelSize: 8
                        elide: Text.ElideRight
                        text: row.modelData === "" ? root.automaticText : row.modelData
                        color: row.current ? Theme.onAccent : Theme.text
                        font { family: row.modelData === "" ? Theme.font : row.modelData; weight: Theme.fontWeight; pixelSize: Theme.px(13) }
                    }

                    Icon {
                        id: check
                        anchors { right: parent.right; rightMargin: 8; verticalCenter: parent.verticalCenter }
                        visible: row.current
                        name: "check"
                        size: 12
                        color: Theme.onAccent
                    }
                }
            }
        }
    }
}
