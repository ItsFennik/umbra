import QtQuick
import qs.config

// Thick macOS Control Center style slider. Emits moved(value) while dragging;
// `value` follows the backing service otherwise.
Item {
    id: root

    property real value: 0
    property string icon
    property bool enabled: true
    signal moved(real value)

    implicitHeight: 24
    opacity: enabled ? 1 : 0.4

    readonly property real shown: area.pressed ? area.dragValue : Math.max(0, Math.min(1, value))

    Rectangle {
        id: track
        anchors.fill: parent
        radius: height / 2
        color: Theme.sliderTrack
        clip: true

        Rectangle {
            height: parent.height
            width: Math.max(parent.height, parent.height + (parent.width - parent.height) * root.shown)
            radius: height / 2
            color: Theme.sliderFill

            // Knob
            Rectangle {
                anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                width: parent.height
                height: parent.height
                radius: height / 2
                color: Theme.sliderKnob
                border { width: 1; color: Theme.dockBorder }
            }
        }
    }

    Icon {
        anchors { left: parent.left; leftMargin: 5; verticalCenter: parent.verticalCenter }
        visible: root.icon !== ""
        name: root.icon
        size: 14
        color: Theme.sliderIcon
    }

    MouseArea {
        id: area

        property real dragValue: 0

        anchors.fill: parent
        enabled: root.enabled
        preventStealing: true
        cursorShape: Qt.PointingHandCursor

        function update(x) {
            dragValue = Math.max(0, Math.min(1, (x - track.height / 2) / (track.width - track.height)));
            root.moved(dragValue);
        }

        onPressed: event => update(event.x)
        onPositionChanged: event => update(event.x)
        onWheel: event => root.moved(Math.max(0, Math.min(1, root.value + (event.angleDelta.y > 0 ? 0.05 : -0.05))))
    }
}
