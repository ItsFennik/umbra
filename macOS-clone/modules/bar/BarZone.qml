import QtQuick
import qs.config

// One zone of the menu bar (left, center or right): its items from BarItems.layout, each built
// from the matching Component in `parts`.
Row {
    id: root

    required property string zone
    required property var parts

    spacing: 2

    Repeater {
        model: BarItems.layout[root.zone]

        delegate: Loader {
            required property string modelData
            anchors.verticalCenter: parent.verticalCenter
            sourceComponent: root.parts[modelData] ?? null
            // Hidden items (no battery, no player, ...) collapse. Binding the Loader's own visible
            // would loop: an item in a hidden Loader always reports itself hidden.
            width: item?.visible ? item.implicitWidth : 0
        }
    }
}
