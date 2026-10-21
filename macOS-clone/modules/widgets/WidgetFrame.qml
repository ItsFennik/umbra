import QtQuick
import Quickshell
import qs.config
import qs.services

// Places one widget, moves it by dragging, and offers its context menu.
Item {
    id: frame

    required property string widgetId
    required property var surface

    readonly property var entry: Widgets.list.find(w => w.id === widgetId) ?? null
    readonly property var type: Widgets.type(entry?.type)
    readonly property var faces: ({ music: musicFace, visualizer: visualizerFace, clock: clockFace })

    function placeAtEntry() {
        x = Qt.binding(() => Math.min(entry?.x ?? 0, surface.width - width));
        y = Qt.binding(() => Math.min(entry?.y ?? 0, surface.height - height));
    }

    Component.onCompleted: {
        placeAtEntry();
        surface.inputRegions = [...surface.inputRegions, inputRegion];
        if (type?.glass)
            surface.blurRegions = [...surface.blurRegions, blurRegion];
    }
    Component.onDestruction: {
        if (!surface)
            return;
        surface.inputRegions = [...surface.inputRegions].filter(r => r !== inputRegion);
        surface.blurRegions = [...surface.blurRegions].filter(r => r !== blurRegion);
    }

    width: type?.width ?? 0
    height: type?.height ?? 0
    scale: dragArea.drag.active ? 1.03 : 1
    Behavior on scale { NumberAnimation { duration: Theme.durationMedium; easing.type: Theme.easing } }

    Region { id: inputRegion; item: frame }
    Region { id: blurRegion; item: frame; radius: 22 }

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
            if (!dragArea.drag.active) {
                Widgets.move(frame.widgetId, frame.x, frame.y);
                frame.placeAtEntry();
            }
        }

        onPressed: mouse => {
            if (mouse.button !== Qt.RightButton)
                return;
            const p = mapToItem(null, mouse.x, mouse.y);
            ContextMenu.openAt([
                { text: "Remove “" + frame.type.text + "”", action: () => Widgets.remove(frame.widgetId) },
                { separator: true },
                ...Widgets.types.map(t => ({ text: "Add " + t.text, action: () => Widgets.add(t.id, frame.surface.screen, p.x + 40, p.y + 40) }))
            ], frame.surface.screen, p.x, p.y);
        }
    }

    Loader {
        id: loader
        anchors.fill: parent
        sourceComponent: frame.faces[frame.entry?.type] ?? null
    }

    Component { id: musicFace; MusicWidget {} }
    Component { id: visualizerFace; VisualizerWidget {} }
    Component { id: clockFace; ClockWidget {} }
}
