import QtQuick
import qs.config

// Thin System Settings slider between `from` and `to`, with end labels.
// Emits moved(value) while dragging; `value` follows the setting otherwise.
Item {
    id: root

    property real value: 0
    property real from: 0
    property real to: 1
    property real stepSize: 0
    property string minLabel
    property string maxLabel
    signal moved(real value)

    implicitWidth: 240
    implicitHeight: labels.visible ? 34 : 20
    opacity: enabled ? 1 : 0.45

    readonly property real fraction: Math.max(0, Math.min(1, (value - from) / (to - from)))
    readonly property real shown: area.pressed ? area.dragFraction : fraction

    Rectangle {
        id: track
        anchors { left: parent.left; right: parent.right; top: parent.top; topMargin: 8; leftMargin: 9; rightMargin: 9 }
        height: 4
        radius: 2
        color: Theme.sliderTrack

        Rectangle {
            width: parent.width * root.shown
            height: parent.height
            radius: 2
            color: Theme.accent
        }
    }

    Rectangle {
        x: track.x + track.width * root.shown - width / 2
        anchors.verticalCenter: track.verticalCenter
        width: 18
        height: 18
        radius: 9
        color: Theme.sliderKnob
        border { width: 1; color: Theme.dockBorder }
    }

    Item {
        id: labels
        visible: root.minLabel !== "" || root.maxLabel !== ""
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
        height: 12

        Text {
            anchors.left: parent.left
            text: root.minLabel
            color: Theme.textSecondary
            font { family: Theme.font; weight: Theme.fontWeight; pixelSize: Theme.px(10) }
        }

        Text {
            anchors.right: parent.right
            text: root.maxLabel
            color: Theme.textSecondary
            font { family: Theme.font; weight: Theme.fontWeight; pixelSize: Theme.px(10) }
        }
    }

    MouseArea {
        id: area

        property real dragFraction: 0

        anchors.fill: parent
        enabled: root.enabled
        preventStealing: true
        cursorShape: Qt.PointingHandCursor

        function update(x) {
            let f = Math.max(0, Math.min(1, (x - track.x) / track.width));
            let v = root.from + f * (root.to - root.from);
            if (root.stepSize > 0) {
                v = +(Math.round(v / root.stepSize) * root.stepSize).toFixed(4);
                f = (v - root.from) / (root.to - root.from);
            }
            dragFraction = f;
            if (v !== root.value)
                root.moved(v);
        }

        onPressed: event => update(event.x)
        onPositionChanged: event => update(event.x)
    }
}
