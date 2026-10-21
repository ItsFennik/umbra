import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import qs.config
import qs.services

// StatusNotifierItem host. Left click activates (or opens the menu for menu-only
// items); right click opens the item's menu, drawn by Umbra so it follows Theme.
Row {
    id: root

    required property var window

    spacing: 0

    Repeater {
        model: SystemTray.items

        delegate: BarButton {
            id: button
            required property SystemTrayItem modelData

            acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
            onClicked: event => {
                if (event.button === Qt.MiddleButton)
                    modelData.secondaryActivate();
                else if (event.button === Qt.RightButton || modelData.onlyMenu)
                    openMenu();
                else
                    modelData.activate();
            }
            onWheel: event => modelData.scroll(event.angleDelta.y, false)

            function openMenu() {
                if (!modelData.hasMenu)
                    return;
                const p = button.mapToItem(null, 0, 0);
                ContextMenu.openTray(modelData.menu, root.window.screen, p.x);
            }

            IconImage {
                implicitSize: 16
                source: button.modelData.icon
                asynchronous: true
                mipmap: true
            }
        }
    }
}
