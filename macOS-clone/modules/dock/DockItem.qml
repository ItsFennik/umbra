import QtQuick
import Quickshell
import Quickshell.Widgets
import qs.config
import qs.services

Item {
    id: item

    required property var modelData
    required property var panel
    property real magnification: 1
    property bool separated: false
    property bool dragged: false
    property real shift: 0

    signal dragStarted(real grab)

    readonly property var windows: Apps.windowsFor(modelData.key)
    readonly property bool running: windows.length > 0
    readonly property string label: modelData.entry ? modelData.entry.name : modelData.appId
    readonly property int size: Math.round(Theme.dockIconSize * magnification)
    readonly property int leading: separated ? panel.separatorWidth : 0

    width: leading + size + Theme.dockSpacing
    height: size
    // Row stacks children from the top; pin to the bottom so magnified icons grow upward.
    anchors.bottom: parent?.bottom
    z: dragged ? 1 : 0
    Behavior on width { enabled: item.magnification === 1 && !item.panel.dragging; NumberAnimation { duration: Theme.durationShort; easing.type: Theme.easing } }

    transform: Translate {
        x: item.dragged ? item.panel.dragX - item.panel.grabX - item.x : item.shift
        y: item.dragged && !item.panel.settling ? Math.max(Math.min(item.panel.dragY - mouse.grabY, 0), -item.panel.maxLift) : 0
        Behavior on x { enabled: !item.dragged && item.panel.dragging && !item.panel.settling; NumberAnimation { duration: Theme.durationMedium; easing.type: Theme.easing } }
        Behavior on y { enabled: item.panel.settling; NumberAnimation { duration: Theme.durationMedium; easing.type: Theme.easing } }
    }

    function launch() {
        if (!modelData.entry)
            return;
        modelData.entry.execute();
        if (Settings.dockAnimateLaunch)
            bounce.restart();
    }

    function activate() {
        if (!running)
            return launch();
        // Cycle through this app's windows when one of them already has focus.
        const current = windows.indexOf(Compositor.activeWindow);
        windows[(current + 1) % windows.length].activate();
    }

    function openMenu() {
        const items = windows.map(w => ({ text: w.title || label, checked: w === Compositor.activeWindow, action: () => w.activate() }));
        const actions = modelData.entry?.actions ?? [];
        if (items.length > 0 && actions.length > 0)
            items.push({ separator: true });
        for (const a of actions)
            items.push({ text: a.name, action: () => a.execute() });
        if (items.length > 0)
            items.push({ separator: true });
        if (modelData.entry)
            items.push(modelData.pinned
                ? { text: "Remove from Dock", action: () => Pins.unpin(modelData.key) }
                : { text: "Keep in Dock", action: () => Pins.pin(modelData.key, null) });
        items.push({ separator: true });
        items.push(running
            ? { text: windows.length > 1 ? "Quit All Windows" : "Quit", action: () => windows.forEach(w => w.close()) }
            : { text: "Open", enabled: modelData.entry !== null, action: () => launch() });
        const p = icon.mapToItem(null, icon.width / 2, 0);
        // An auto-hidden dock reserves no space, so lift the menu above it.
        ContextMenu.open(items, panel.screen, p.x, "bottom", panel.autoHide ? panel.bodyHeight + Theme.dockMargin : 0);
    }

    // Divider between pinned apps and other running apps.
    Rectangle {
        visible: item.separated
        x: (item.panel.separatorWidth - Theme.dockSpacing) / 2
        anchors.verticalCenter: icon.verticalCenter
        width: 1
        height: Theme.dockIconSize * 0.75
        color: Theme.dockBorder
    }

    IconImage {
        id: icon
        x: item.leading + Theme.dockSpacing / 2
        anchors.bottom: parent.bottom
        implicitSize: item.size
        source: Apps.iconFor(item.modelData.entry, item.modelData.appId)
        asynchronous: true
        mipmap: true
        opacity: item.dragged && item.panel.removing ? 0.45 : 1
        transform: Translate { id: lift }
        Behavior on opacity { NumberAnimation { duration: Theme.durationShort } }
    }

    Rectangle {
        anchors { horizontalCenter: icon.horizontalCenter; top: parent.bottom; topMargin: 3 }
        width: 4
        height: 4
        radius: 2
        color: Theme.indicator
        opacity: Settings.dockShowIndicators && item.running && !(item.dragged && !item.panel.settling) ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.durationMedium } }
    }

    // Launch feedback: a single restrained bounce.
    SequentialAnimation {
        id: bounce
        NumberAnimation { target: lift; property: "y"; to: -12; duration: 180; easing.type: Easing.OutQuad }
        NumberAnimation { target: lift; property: "y"; to: 0; duration: 260; easing.type: Easing.OutBounce }
    }

    MouseArea {
        id: mouse

        property real grabX: 0
        property real grabY: 0
        property bool dragging: false

        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
        preventStealing: true

        onPressed: event => {
            grabX = event.x;
            grabY = event.y;
        }
        onPositionChanged: event => {
            if (!pressed || !(pressedButtons & Qt.LeftButton) || item.panel.settling)
                return;
            if (!dragging && Math.hypot(event.x - grabX, event.y - grabY) > Qt.styleHints.startDragDistance) {
                dragging = true;
                item.dragStarted(grabX);
            }
            if (dragging) {
                const p = mapToItem(item.parent, event.x, event.y);
                item.panel.updateDrag(p.x, p.y);
            }
        }
        onReleased: event => {
            if (dragging) {
                dragging = false;
                item.panel.endDrag();
            } else if (containsMouse && !item.panel.dragging) {
                if (event.button === Qt.RightButton)
                    item.openMenu();
                else
                    event.button === Qt.MiddleButton ? item.launch() : item.activate();
            }
        }
        onCanceled: {
            if (dragging) {
                dragging = false;
                item.panel.resetDrag();
            }
        }
    }

    Rectangle {
        id: tooltip

        readonly property bool removeHint: item.dragged && item.panel.removing

        anchors { horizontalCenter: icon.horizontalCenter; bottom: icon.top; bottomMargin: 10 }
        width: tooltipText.implicitWidth + 20
        height: tooltipText.implicitHeight + 8
        radius: Theme.radiusSmall
        color: Theme.tooltipBackground
        border { width: 1; color: Theme.dockBorder }
        opacity: removeHint || (mouse.containsMouse && !item.panel.dragging && Panels.current !== "menu") ? 1 : 0
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: Theme.durationShort } }

        Text {
            id: tooltipText
            anchors.centerIn: parent
            text: tooltip.removeHint ? "Remove from Dock" : item.label
            color: Theme.text
            font { family: Theme.font; pixelSize: 12 }
        }
    }
}
