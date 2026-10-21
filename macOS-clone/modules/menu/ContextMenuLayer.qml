import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.components
import qs.config
import qs.services

// Renders ContextMenu: tray menus (with drill-in submenus) and dock menus.
LazyLoader {
    active: Panels.current === "menu"

    PopupSurface {
        id: surface

        panelName: "menu"
        BackgroundEffect.blurRegion: Region { item: Theme.blur ? panel : null }

        // Submenus open in place; the last handle is the one shown.
        property var stack: ContextMenu.handle ? [ContextMenu.handle] : []
        readonly property var currentHandle: stack.length > 0 ? stack[stack.length - 1] : null

        function stripMnemonic(text) {
            return text.replace(/__/g, "\0").replace(/_/g, "").replace(/\0/g, "_");
        }

        function run(action) {
            ContextMenu.close();
            action();
        }

        // Reopening on another tray item while open replaces the menu.
        Connections {
            target: ContextMenu
            function onHandleChanged() { surface.stack = ContextMenu.handle ? [ContextMenu.handle] : []; }
        }

        QsMenuOpener {
            id: opener
            menu: surface.currentHandle
        }

        Rectangle {
            id: panel

            readonly property real maxRow: {
                let w = 0;
                for (const c of column.children)
                    w = Math.max(w, c.implicitWidth);
                return w;
            }

            x: {
                const left = ContextMenu.edge === "bottom" ? ContextMenu.anchorX - width / 2 : ContextMenu.anchorX;
                return Math.max(Theme.panelGap, Math.min(left, surface.width - width - Theme.panelGap));
            }
            // The surface starts below the bar, so point menus shift up by its height.
            y: ContextMenu.edge === "bottom" ? surface.height - height - Theme.panelGap - ContextMenu.bottomInset
                : ContextMenu.edge === "point" ? Math.max(4, Math.min(ContextMenu.anchorY - Theme.barHeight, surface.height - height - Theme.panelGap))
                : 4
            width: Math.max(180, Math.min(340, maxRow)) + 10
            height: column.implicitHeight + 10
            radius: Theme.radiusMedium
            color: Theme.popupBackground
            border { width: 1; color: Theme.dockBorder }

            opacity: 0
            Component.onCompleted: opacity = 1
            Behavior on opacity { NumberAnimation { duration: Theme.durationShort } }

            MouseArea { anchors.fill: parent }

            Column {
                id: column
                anchors { left: parent.left; right: parent.right; top: parent.top; margins: 5 }

                MenuRow {
                    width: parent.width
                    visible: surface.stack.length > 1
                    back: true
                    text: "Back"
                    onClicked: surface.stack = surface.stack.slice(0, -1)
                }

                Repeater {
                    model: surface.currentHandle ? opener.children : []

                    delegate: MenuRow {
                        required property QsMenuEntry modelData

                        width: parent.width
                        separator: modelData.isSeparator
                        text: surface.stripMnemonic(modelData.text)
                        enabled: modelData.enabled
                        checked: modelData.buttonType !== QsMenuButtonType.None && modelData.checkState === Qt.Checked
                        hasChildren: modelData.hasChildren
                        onClicked: {
                            if (modelData.hasChildren) {
                                surface.stack = surface.stack.concat([modelData]);
                            } else {
                                modelData.triggered();
                                ContextMenu.close();
                            }
                        }
                    }
                }

                Repeater {
                    model: surface.currentHandle ? [] : ContextMenu.items

                    delegate: MenuRow {
                        required property var modelData

                        width: parent.width
                        separator: modelData.separator ?? false
                        text: modelData.text ?? ""
                        enabled: modelData.enabled ?? true
                        checked: modelData.checked ?? false
                        onClicked: if (modelData.action) surface.run(modelData.action)
                    }
                }
            }
        }
    }
}
