import QtQuick
import qs.components
import qs.config
import qs.services

// Drag-and-drop editor for the menu bar: chips in Left / Center / Right zones and an Available tray.
// While dragging, a marker shows where the chip would land; dropping it in Available takes it off the bar.
// The chip models stay fixed during a drag (rebuilding them would drop the pointer grab).
Item {
    id: root

    implicitHeight: zones.implicitHeight

    // Chip being dragged and where it would land; dragId is "" when idle.
    property string dragId: ""
    property string dropZone: ""
    property int dropIndex: -1
    property point dragPos
    // Insertion marker in this item's coordinates; width 0 hides it.
    property rect marker: Qt.rect(0, 0, 0, 0)

    readonly property var zoneList: [
        { id: "left", text: "Left" },
        { id: "center", text: "Center" },
        { id: "right", text: "Right" },
        { id: "unused", text: "Available" }
    ]

    function idsFor(zone) {
        return zone === "unused" ? BarItems.unused : BarItems.layout[zone];
    }

    function startDrag(id, pos) {
        dragPos = pos;
        dragId = id;
        updateDrop();
    }

    function moveDrag(pos) {
        dragPos = pos;
        updateDrop();
    }

    function endDrag() {
        if (dragId !== "" && dropZone !== "")
            BarItems.move(dragId, dropZone, dropIndex);
        dragId = "";
        dropZone = "";
        dropIndex = -1;
        marker = Qt.rect(0, 0, 0, 0);
    }

    // Zone under the pointer, and the insertion index among its chips other than the dragged one.
    function updateDrop() {
        for (let i = 0; i < zoneRepeater.count; i++) {
            const zone = zoneRepeater.itemAt(i);
            const p = zone.flow.mapFromItem(root, dragPos.x, dragPos.y);
            if (p.y < -zone.flow.y || p.y > zone.height - zone.flow.y)
                continue;
            let index = 0;
            let after = null, before = null;
            for (const chip of zone.chips()) {
                if (chip.itemId === dragId)
                    continue;
                const rowAbove = chip.y + chip.height < p.y;
                const sameRowBefore = p.y >= chip.y && p.y <= chip.y + chip.height && chip.x + chip.width / 2 < p.x;
                if (rowAbove || sameRowBefore) {
                    index++;
                    after = chip;
                } else if (!before) {
                    before = chip;
                }
            }
            dropZone = zone.zoneId;
            dropIndex = index;
            if (zone.zoneId === "unused") {
                marker = Qt.rect(0, 0, 0, 0);
            } else {
                const m = before ? before.mapToItem(root, -4, 0) : after ? after.mapToItem(root, after.width + 2, 0) : zone.flow.mapToItem(root, 0, 0);
                marker = Qt.rect(m.x, m.y, 2, 26);
            }
            return;
        }
        dropZone = "";
        dropIndex = -1;
        marker = Qt.rect(0, 0, 0, 0);
    }

    Column {
        id: zones
        width: parent.width

        Repeater {
            id: zoneRepeater
            model: root.zoneList

            delegate: Item {
                id: zone

                required property var modelData
                required property int index
                readonly property string zoneId: modelData.id
                readonly property bool target: root.dragId !== "" && root.dropZone === zoneId
                property alias flow: flow

                function chips() {
                    const out = [];
                    for (let i = 0; i < chipRepeater.count; i++)
                        out.push(chipRepeater.itemAt(i));
                    return out;
                }

                width: parent.width
                height: Math.max(48, flow.height + 20)

                Rectangle {
                    visible: zone.index > 0
                    anchors { left: parent.left; right: parent.right; top: parent.top; leftMargin: 12; rightMargin: 12 }
                    height: 1
                    color: Theme.hairline
                }

                Rectangle {
                    anchors { fill: parent; margins: 4 }
                    radius: Theme.radiusSmall
                    color: zone.target ? Qt.alpha(Theme.accent, 0.12) : "transparent"
                    border { width: zone.target ? 1 : 0; color: Theme.accent }
                }

                Text {
                    id: label
                    anchors { left: parent.left; leftMargin: 12; verticalCenter: parent.verticalCenter }
                    width: 72
                    text: zone.modelData.text
                    color: zone.zoneId === "unused" ? Theme.textSecondary : Theme.text
                    font { family: Theme.font; weight: Theme.fontWeight; pixelSize: Theme.px(13) }
                }

                Flow {
                    id: flow
                    anchors { left: label.right; right: parent.right; rightMargin: 12; verticalCenter: parent.verticalCenter }
                    spacing: 6

                    Text {
                        visible: chipRepeater.count === 0
                        height: 26
                        verticalAlignment: Text.AlignVCenter
                        text: zone.zoneId === "unused" ? "Every item is on the bar" : "Drag items here"
                        color: Theme.textSecondary
                        font { family: Theme.font; weight: Theme.fontWeight; pixelSize: Theme.px(11) }
                    }

                    Repeater {
                        id: chipRepeater
                        model: root.idsFor(zone.zoneId)

                        delegate: Rectangle {
                            id: chip

                            required property string modelData
                            readonly property string itemId: modelData
                            readonly property var item: BarItems.find(modelData)

                            width: chipRow.implicitWidth + 20
                            height: 26
                            radius: 13
                            color: Theme.tileOff
                            border { width: 1; color: Theme.hairline }
                            opacity: root.dragId === itemId ? 0.35 : 1

                            Row {
                                id: chipRow
                                anchors.centerIn: parent
                                spacing: 6

                                Icon {
                                    anchors.verticalCenter: parent.verticalCenter
                                    name: chip.item?.icon ?? ""
                                    size: 12
                                }

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: chip.item?.text ?? ""
                                    color: Theme.text
                                    font { family: Theme.font; weight: Theme.fontWeight; pixelSize: Theme.px(12) }
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                preventStealing: true
                                cursorShape: root.dragId !== "" ? Qt.ClosedHandCursor : Qt.OpenHandCursor
                                onPressed: mouse => root.startDrag(chip.itemId, mapToItem(root, mouse.x, mouse.y))
                                onPositionChanged: mouse => root.moveDrag(mapToItem(root, mouse.x, mouse.y))
                                onReleased: root.endDrag()
                                onCanceled: root.endDrag()
                            }
                        }
                    }
                }
            }
        }
    }

    Rectangle {
        visible: root.dragId !== "" && root.marker.width > 0
        x: root.marker.x
        y: root.marker.y
        z: 9
        width: root.marker.width
        height: root.marker.height
        radius: 1
        color: Theme.accent
    }

    // The chip under the pointer while dragging.
    Rectangle {
        id: ghost

        readonly property var item: BarItems.find(root.dragId)

        visible: root.dragId !== ""
        x: root.dragPos.x - width / 2
        y: root.dragPos.y - height / 2
        z: 10
        width: ghostRow.implicitWidth + 20
        height: 26
        radius: 13
        color: Theme.accent
        opacity: 0.92

        Row {
            id: ghostRow
            anchors.centerIn: parent
            spacing: 6

            Icon {
                anchors.verticalCenter: parent.verticalCenter
                name: ghost.item?.icon ?? ""
                size: 12
                color: Theme.onAccent
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: ghost.item?.text ?? ""
                color: Theme.onAccent
                font { family: Theme.font; weight: Theme.fontWeight; pixelSize: Theme.px(12) }
            }
        }
    }
}
