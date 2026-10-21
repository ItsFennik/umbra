import QtQuick
import qs.config
import qs.services

// Cava bars. Keeps cava running while it is visible.
Item {
    id: root

    property int bars: 32
    property real spacing: 3
    property color color: Theme.accent
    property real minLength: 3
    // Bass in the middle, falling off to both sides.
    property bool centered: false
    // Bars grow up and down from the middle instead of up from the bottom.
    property bool mirrored: false
    // Dim bars toward the sides.
    property bool fadeEdges: false

    property bool acquired: false
    function sync() {
        if (visible === acquired)
            return;
        acquired = visible;
        if (acquired)
            Cava.acquire();
        else
            Cava.release();
    }
    onVisibleChanged: sync()
    Component.onCompleted: sync()
    Component.onDestruction: if (acquired) Cava.release()

    Row {
        anchors.fill: parent
        spacing: root.spacing

        Repeater {
            model: root.bars

            delegate: Item {
                required property int index
                readonly property real fromCenter: Math.abs(index - (root.bars - 1) / 2) / ((root.bars - 1) / 2)
                readonly property real level: Cava.at(root.centered ? fromCenter : index / (root.bars - 1))

                width: (root.width - root.spacing * (root.bars - 1)) / root.bars
                height: root.height

                Rectangle {
                    anchors.bottom: root.mirrored ? undefined : parent.bottom
                    anchors.verticalCenter: root.mirrored ? parent.verticalCenter : undefined
                    width: parent.width
                    height: Math.max(root.minLength, parent.level * parent.height)
                    radius: width / 2
                    color: root.color
                    opacity: root.fadeEdges ? 1 - parent.fromCenter * 0.7 : 1

                    Behavior on height { NumberAnimation { duration: Theme.ms(70) } }
                }
            }
        }
    }
}
