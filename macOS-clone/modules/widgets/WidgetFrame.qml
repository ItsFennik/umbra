import QtQuick
import Quickshell
import qs.components
import qs.config
import qs.services

// Places one widget: drag to move it, drag the corner grip to resize it (Shift keeps the
// aspect ratio), right-click for its menu. Stacking follows Widgets.list order.
Item {
    id: frame

    required property string widgetId
    required property var surface

    readonly property var entry: Widgets.list.find(w => w.id === widgetId) ?? null
    readonly property var type: Widgets.type(entry?.type)
    readonly property var size: Widgets.sizeOf(entry)
    readonly property bool editing: hover.hovered || dragArea.drag.active || resizeArea.pressed

    function placeAtEntry() {
        width = Qt.binding(() => size.width);
        height = Qt.binding(() => size.height);
        x = Qt.binding(() => Math.max(0, Math.min(entry?.x ?? 0, surface.width - width)));
        y = Qt.binding(() => Math.max(0, Math.min(entry?.y ?? 0, surface.height - height)));
    }

    function commit() {
        Widgets.setGeometry(widgetId, x, y, width, height);
        placeAtEntry();
    }

    Component.onCompleted: {
        placeAtEntry();
        surface.inputRegions = [...surface.inputRegions, inputRegion];
        surface.blurRegions = [...surface.blurRegions, blurRegion];
    }
    Component.onDestruction: {
        if (!surface)
            return;
        surface.inputRegions = [...surface.inputRegions].filter(r => r !== inputRegion);
        surface.blurRegions = [...surface.blurRegions].filter(r => r !== blurRegion);
    }

    visible: type !== null
    z: Widgets.list.indexOf(entry)
    scale: dragArea.drag.active ? 1.03 : 1
    Behavior on scale { NumberAnimation { duration: Theme.durationMedium; easing.type: Theme.easing } }

    Region { id: inputRegion; item: frame.visible ? frame : null }
    Region { id: blurRegion; item: frame.visible && frame.type?.glass ? frame : null; radius: 22 }

    HoverHandler { id: hover }

    MouseArea {
        id: dragArea
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: dragArea.drag.active ? Qt.ClosedHandCursor : Qt.ArrowCursor

        drag.target: frame
        drag.minimumX: 0
        drag.minimumY: 0
        drag.maximumX: frame.surface.width - frame.width
        drag.maximumY: frame.surface.height - frame.height
        drag.onActiveChanged: {
            if (!dragArea.drag.active)
                frame.commit();
        }

        onPressed: mouse => {
            if (mouse.button !== Qt.RightButton)
                return;
            const p = mapToItem(null, mouse.x, mouse.y);
            const name = frame.type.text;
            const last = Widgets.list.length - 1;
            const index = Widgets.list.indexOf(frame.entry);
            ContextMenu.openAt([
                { text: "Widget Settings…", action: () => { Settings.widgetFocus = frame.widgetId; Settings.openPage("widgets"); } },
                { text: "Bring to Front", enabled: index < last, action: () => Widgets.raise(frame.widgetId) },
                { text: "Send to Back", enabled: index > 0, action: () => Widgets.lower(frame.widgetId) },
                { text: "Reset Size", enabled: frame.type.resizable && frame.entry.width !== undefined, action: () => Widgets.resetSize(frame.widgetId) },
                { text: "Remove “" + name + "”", action: () => Widgets.remove(frame.widgetId) },
                { separator: true },
                ...Widgets.types.map(t => ({ text: "Add " + t.text, action: () => Widgets.add(t.id, frame.surface.screen, p.x + 40, p.y + 40) }))
            ], frame.surface.screen, p.x, p.y);
        }
    }

    Loader {
        id: loader
        anchors.fill: parent
        source: frame.type ? Qt.resolvedUrl(frame.type.id + "/Widget.qml") : ""
        onLoaded: {
            if (!("options" in item)) {
                console.warn("Umbra: widget", frame.type.id, "is not a WidgetBase");
                return;
            }
            item.widgetId = Qt.binding(() => frame.widgetId);
            item.options = Qt.binding(() => Widgets.optionsFor(frame.entry));
            item.screen = Qt.binding(() => frame.surface.screen);
        }
        onStatusChanged: if (status === Loader.Error) console.warn("Umbra: cannot load widget", frame.type?.id)
    }

    // Shown instead of a widget that failed to load.
    WidgetCard {
        visible: loader.status === Loader.Error

        Text {
            anchors.centerIn: parent
            width: parent.width - 32
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            text: "“" + (frame.type?.text ?? "") + "” could not be loaded"
            color: Theme.textSecondary
            font { family: Theme.font; weight: Theme.fontWeight; pixelSize: Theme.px(12) }
        }
    }

    // Bounds outline while hovered, so frameless widgets can be found and resized.
    Rectangle {
        anchors.fill: parent
        radius: 22
        color: "transparent"
        border { width: 1; color: Qt.rgba(1, 1, 1, 0.35) }
        opacity: frame.editing && !frame.type?.glass ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.durationShort } }
    }

    MouseArea {
        id: resizeArea

        property real startWidth
        property real startHeight
        property point start

        anchors { right: parent.right; bottom: parent.bottom }
        width: 22
        height: 22
        visible: frame.type?.resizable ?? false
        hoverEnabled: true
        preventStealing: true
        cursorShape: Qt.SizeFDiagCursor
        opacity: frame.editing ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.durationShort } }

        onPressed: mouse => {
            start = mapToItem(null, mouse.x, mouse.y);
            startWidth = frame.width;
            startHeight = frame.height;
        }
        onPositionChanged: mouse => {
            if (!pressed)
                return;
            const p = mapToItem(null, mouse.x, mouse.y);
            const t = frame.type;
            let w = startWidth + p.x - start.x;
            let h = startHeight + p.y - start.y;
            if (mouse.modifiers & Qt.ShiftModifier) {
                const k = Math.max(w / startWidth, h / startHeight);
                w = startWidth * k;
                h = startHeight * k;
            }
            const size = Widgets.clampSize(t, Math.min(w, frame.surface.width - frame.x), Math.min(h, frame.surface.height - frame.y));
            frame.width = size.width;
            frame.height = size.height;
        }
        onReleased: frame.commit()

        // Grip: two short diagonal strokes in the corner.
        Repeater {
            model: [10, 5]

            delegate: Rectangle {
                required property int modelData
                x: resizeArea.width - 4 - modelData - 1
                y: resizeArea.height - 4 - 1
                width: modelData * Math.SQRT2
                height: 1.5
                radius: 1
                color: Qt.rgba(1, 1, 1, 0.7)
                transformOrigin: Item.Left
                rotation: -45
            }
        }
    }
}
