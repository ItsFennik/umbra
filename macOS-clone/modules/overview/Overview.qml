import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import qs.components
import qs.config
import qs.services

// Workspaces strip plus live window thumbnails. Windows are filtered to the
// active workspace only when the compositor adapter can map them; otherwise
// every window is shown and the overview says so.
// Toggle with: qs -p <umbra dir> ipc call overview toggle
Scope {
    IpcHandler {
        target: "overview"

        function toggle(): void { Panels.toggle("overview"); }
        function open(): void { Panels.open("overview"); }
        function close(): void { Panels.close(); }
    }

    LazyLoader {
        active: Panels.current === "overview"

        PanelWindow {
            id: window

            screen: Compositor.focusedScreen ?? Quickshell.screens[0]
            anchors { top: true; bottom: true; left: true; right: true }
            exclusionMode: ExclusionMode.Ignore
            color: "transparent"

            WlrLayershell.namespace: "umbra-overview"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
            BackgroundEffect.blurRegion: Region { item: Theme.blur ? backdrop : null }

            readonly property var workspaces: Compositor.workspacesFor(window.screen)
            readonly property var activeWorkspace: workspaces.find(w => w.active) ?? null
            readonly property bool filtered: Compositor.windowWorkspacesAvailable && activeWorkspace !== null
            readonly property var windows: filtered
                ? Compositor.windows.filter(w => Compositor.workspaceNameOf(w) === activeWorkspace.name)
                : Compositor.windows

            function pick(toplevel) {
                toplevel.activate();
                Panels.close();
            }

            Rectangle {
                id: backdrop
                anchors.fill: parent
                color: Qt.rgba(0, 0, 0, Theme.dark ? 0.5 : 0.3)
                opacity: 0
                Component.onCompleted: opacity = 1
                Behavior on opacity { NumberAnimation { duration: Theme.durationMedium } }

                MouseArea {
                    anchors.fill: parent
                    onClicked: Panels.close()
                }
            }

            Item {
                anchors.fill: parent
                focus: true
                Keys.onEscapePressed: Panels.close()
            }

            // Workspaces
            Row {
                id: strip
                anchors { horizontalCenter: parent.horizontalCenter; top: parent.top; topMargin: 28 }
                visible: Compositor.workspacesAvailable
                spacing: 10

                Repeater {
                    model: window.workspaces

                    delegate: MouseArea {
                        id: space
                        required property var modelData

                        width: 132
                        height: 74 + 22
                        enabled: modelData.canActivate || modelData.active
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: modelData.activate()

                        Rectangle {
                            width: parent.width
                            height: 74
                            radius: Theme.radiusMedium
                            color: Theme.popupBackground
                            border {
                                width: space.modelData.active ? 2 : 1
                                color: space.modelData.active ? Theme.accent : space.containsMouse ? Theme.text : Theme.dockBorder
                            }

                            Text {
                                anchors.centerIn: parent
                                visible: Compositor.windowWorkspacesAvailable
                                text: {
                                    const n = Compositor.windows.filter(w => Compositor.workspaceNameOf(w) === space.modelData.name).length;
                                    return n === 0 ? "Empty" : n === 1 ? "1 window" : n + " windows";
                                }
                                color: Theme.textSecondary
                                font { family: Theme.font; weight: Theme.fontWeight; pixelSize: Theme.px(11) }
                            }
                        }

                        Text {
                            anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom }
                            text: "Desktop " + space.modelData.name
                            color: "white"
                            font { family: Theme.font; pixelSize: Theme.px(12); weight: Theme.weight(space.modelData.active ? Font.DemiBold : Font.Normal) }
                        }
                    }
                }
            }

            Text {
                anchors { horizontalCenter: parent.horizontalCenter; top: strip.visible ? strip.bottom : parent.top; topMargin: 14 }
                visible: !window.filtered
                text: "Showing windows from all workspaces — this compositor does not report window workspaces."
                color: Qt.rgba(1, 1, 1, 0.7)
                font { family: Theme.font; weight: Theme.fontWeight; pixelSize: Theme.px(12) }
            }

            // Window grid
            Item {
                id: area
                anchors { left: parent.left; right: parent.right; top: strip.bottom; bottom: parent.bottom; margins: 60; topMargin: 50 }

                readonly property int count: window.windows.length
                readonly property int spacing: 28
                // Pick the column count that gives the largest 16:10 tiles.
                readonly property int columns: {
                    let best = 1, bestWidth = 0;
                    for (let c = 1; c <= Math.max(1, count); c++) {
                        const rows = Math.ceil(count / c);
                        const w = Math.min((width - (c - 1) * spacing) / c, ((height - (rows - 1) * spacing) / rows - 24) * 1.6);
                        if (w > bestWidth) { bestWidth = w; best = c; }
                    }
                    return best;
                }
                readonly property real tileWidth: Math.min(480, (width - (columns - 1) * spacing) / columns)
                readonly property real tileHeight: Math.min(tileWidth / 1.6, (height - (Math.ceil(count / columns) - 1) * spacing) / Math.ceil(Math.max(1, count) / columns) - 24)

                Text {
                    anchors.centerIn: parent
                    visible: area.count === 0
                    text: "No open windows"
                    color: Qt.rgba(1, 1, 1, 0.7)
                    font { family: Theme.font; weight: Theme.fontWeight; pixelSize: Theme.px(14) }
                }

                Flow {
                    anchors.centerIn: parent
                    width: Math.min(parent.width, area.columns * area.tileWidth + (area.columns - 1) * area.spacing)
                    spacing: area.spacing

                    Repeater {
                        model: window.windows

                        delegate: MouseArea {
                            id: tile
                            required property var modelData

                            readonly property var entry: Apps.entryFor(modelData)

                            width: area.tileWidth
                            height: area.tileHeight + 24
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: window.pick(modelData)

                            Item {
                                id: frame
                                width: parent.width
                                height: area.tileHeight

                                ScreencopyView {
                                    id: preview
                                    anchors.centerIn: parent
                                    captureSource: tile.modelData
                                    // Continuous capture stalled the overlay's first frame on
                                    // Hyprland 0.56; periodic one-shot captures do not.
                                    live: false
                                    constraintSize: Qt.size(frame.width, frame.height)
                                }

                                Timer {
                                    interval: 1000
                                    repeat: true
                                    running: true
                                    onTriggered: preview.captureFrame()
                                }

                                // Without capture support, fall back to the app icon.
                                Rectangle {
                                    anchors.fill: parent
                                    visible: !preview.hasContent
                                    radius: Theme.radiusMedium
                                    color: Theme.popupBackground

                                    IconImage {
                                        anchors.centerIn: parent
                                        implicitSize: 64
                                        source: Apps.iconFor(tile.entry, tile.modelData.appId)
                                        asynchronous: true
                                        mipmap: true
                                    }
                                }

                                Rectangle {
                                    anchors.centerIn: parent
                                    width: (preview.hasContent ? preview.width : parent.width) + 8
                                    height: (preview.hasContent ? preview.height : parent.height) + 8
                                    radius: Theme.radiusMedium + 2
                                    color: "transparent"
                                    border { width: 3; color: Theme.accent }
                                    visible: tile.containsMouse
                                }
                            }

                            Row {
                                anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom }
                                spacing: 6

                                IconImage {
                                    anchors.verticalCenter: parent.verticalCenter
                                    implicitSize: 16
                                    source: Apps.iconFor(tile.entry, tile.modelData.appId)
                                    asynchronous: true
                                    mipmap: true
                                }

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: Math.min(implicitWidth, tile.width - 30)
                                    text: tile.modelData.title || Apps.nameFor(tile.modelData)
                                    elide: Text.ElideRight
                                    color: "white"
                                    font { family: Theme.font; pixelSize: Theme.px(12); weight: Theme.weight(tile.containsMouse ? Font.DemiBold : Font.Normal) }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
