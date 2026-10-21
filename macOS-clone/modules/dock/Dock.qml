import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.config
import qs.services

PanelWindow {
    id: dock

    required property ShellScreen modelData
    screen: modelData

    readonly property int slot: Theme.dockIconSize + Theme.dockSpacing
    readonly property int separatorWidth: 13
    readonly property int bodyHeight: Theme.dockIconSize + Theme.dockPadding * 2 + 6
    readonly property real maxScale: Settings.dockMagnification ? Settings.dockMagnificationScale : 1
    // Room above the dock for magnified icons, tooltips and icons dragged out for removal.
    readonly property int headroom: Math.max(Math.ceil(Theme.dockIconSize * (maxScale - 1)), Theme.dockIconSize) + 44
    readonly property int maxLift: Theme.dockIconSize + 6

    readonly property var apps: Settings.dockShowRunning ? Apps.dockApps : Apps.dockApps.filter(a => a.pinned)
    readonly property int pinnedCount: apps.filter(a => a.pinned).length
    readonly property bool hasSeparator: pinnedCount > 0 && pinnedCount < apps.length

    // Pointer x in un-magnified layout space, so magnification cannot feed back into itself.
    property real pointerX: -1
    readonly property bool hovered: hover.hovered
    // Auto-hide slides the dock off the bottom edge until the pointer touches it.
    readonly property bool autoHide: Settings.dockAutoHide
    readonly property bool revealed: !autoHide || hovered || dragging || (Panels.current === "menu" && ContextMenu.edge === "bottom")

    // Drag state. dropIndex is the dragged item's final position in the list.
    property int dragFrom: -1
    property int dropIndex: -1
    property real dragX: 0
    property real dragY: 0
    property real grabX: 0
    property bool settling: false
    readonly property bool dragging: dragFrom >= 0
    readonly property bool removing: dragging && !settling && apps[dragFrom]?.pinned && dragY < -Theme.dockIconSize

    function baseCenter(index) {
        return (index + 0.5) * slot + (hasSeparator && index >= pinnedCount ? separatorWidth : 0);
    }

    function shiftFor(index) {
        if (!dragging || index === dragFrom)
            return 0;
        const to = removing ? apps.length - 1 : dropIndex;
        if (dragFrom < to && index > dragFrom && index <= to)
            return -slot;
        if (to < dragFrom && index >= to && index < dragFrom)
            return slot;
        return 0;
    }

    function beginDrag(index, grab) {
        dragFrom = index;
        dropIndex = index;
        grabX = grab;
        pointerX = -1;
    }

    function updateDrag(x, y) {
        if (settling)
            return;
        dragX = x;
        dragY = y;
        const center = x - grabX + Theme.dockIconSize / 2;
        let index = 0;
        for (let i = 0; i < apps.length; i++) {
            if (i !== dragFrom && baseCenter(i) < center)
                index++;
        }
        dropIndex = index;
    }

    function endDrag() {
        if (!dragging || settling)
            return;
        if (removing) {
            const key = apps[dragFrom].key;
            resetDrag();
            Pins.unpin(key);
            return;
        }
        // Glide into the slot before committing so the reorder does not jump.
        const target = repeater.itemAt(dropIndex);
        settling = true;
        settle.to = (target ? target.x + (dropIndex > dragFrom ? target.width - repeater.itemAt(dragFrom).width : 0) : 0) + grabX;
        settle.start();
    }

    function commitDrop() {
        const app = apps[dragFrom];
        const others = apps.filter((_, i) => i !== dragFrom);
        const pinnedOthers = pinnedCount - (app.pinned ? 1 : 0);
        const shouldPin = dropIndex <= pinnedOthers || app.pinned;
        const before = dropIndex < pinnedOthers ? others[dropIndex].key : null;
        // Reset first so the reorder lands without stale drag offsets.
        resetDrag();
        if (shouldPin)
            Pins.pin(app.key, before);
    }

    // Offsets drop to zero while settling is set, so no slide animation runs
    // against the reorder that follows.
    function resetDrag() {
        settling = true;
        dragFrom = -1;
        dropIndex = -1;
        settling = false;
    }

    NumberAnimation {
        id: settle
        target: dock
        property: "dragX"
        duration: Theme.durationMedium
        easing.type: Theme.easing
        onFinished: dock.commitDrop()
    }

    anchors {
        bottom: true
        left: true
        right: true
    }
    implicitHeight: bodyHeight + Theme.dockMargin + headroom
    exclusiveZone: autoHide ? 0 : bodyHeight + Theme.dockMargin
    color: "transparent"

    WlrLayershell.namespace: "umbra-dock"
    WlrLayershell.layer: WlrLayer.Top
    BackgroundEffect.blurRegion: Region { item: Theme.blur ? body : null }
    // Only the dock itself takes input; the magnification headroom joins while hovered.
    mask: Region { item: dock.hovered || dock.dragging ? hoverArea : dock.revealed ? body : edgeTrigger }

    // Passive handler on the window root, which is an ancestor of every icon,
    // so it tracks the pointer without stealing hover from them. Input outside
    // the mask never reaches the surface.
    HoverHandler {
        id: hover
        onPointChanged: {
            if (dock.dragging)
                return;
            const baseWidth = dock.apps.length * dock.slot + (dock.hasSeparator ? dock.separatorWidth : 0);
            dock.pointerX = hovered ? point.position.x - hoverArea.x - (hoverArea.width - baseWidth) / 2 : -1;
        }
        onHoveredChanged: if (!hovered) dock.pointerX = -1
    }

    // Strip along the bottom edge that reveals an auto-hidden dock.
    Item {
        id: edgeTrigger
        anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom }
        width: body.width
        height: 2
    }

    Item {
        id: hoverArea
        anchors { horizontalCenter: parent.horizontalCenter; bottom: body.bottom; top: parent.top }
        width: body.width
    }

    Rectangle {
        id: body
        anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: dock.revealed ? Theme.dockMargin : -dock.bodyHeight - 2 }
        Behavior on anchors.bottomMargin { NumberAnimation { duration: Theme.durationMedium; easing.type: Theme.easing } }
        width: row.width + Theme.dockPadding * 2 - (dock.removing ? dock.slot : 0)
        height: dock.bodyHeight
        radius: Theme.dockRadius
        color: Theme.dockBackground
        border { width: 1; color: Theme.dockBorder }
        Behavior on color { ColorAnimation { duration: Theme.durationMedium } }
        Behavior on width { enabled: dock.dragging && !dock.settling; NumberAnimation { duration: Theme.durationMedium; easing.type: Theme.easing } }
    }

    Row {
        id: row
        anchors { horizontalCenter: parent.horizontalCenter; bottom: body.bottom; bottomMargin: Theme.dockPadding + 6 }
        spacing: 0

        Repeater {
            id: repeater

            model: ScriptModel {
                values: dock.apps
                objectProp: "key"
            }

            delegate: DockItem {
                required property int index

                panel: dock
                separated: dock.hasSeparator && index === dock.pinnedCount
                dragged: index === dock.dragFrom
                shift: dock.shiftFor(index)
                magnification: {
                    if (dock.pointerX < 0 || dock.maxScale === 1 || dock.dragging)
                        return 1;
                    const d = dock.baseCenter(index) - dock.pointerX;
                    const sigma = dock.slot * 1.1;
                    return 1 + (dock.maxScale - 1) * Math.exp(-(d * d) / (2 * sigma * sigma));
                }
                onDragStarted: grab => dock.beginDrag(index, grab)
            }
        }
    }
}
