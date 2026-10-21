pragma Singleton
import QtQuick
import Quickshell
import qs.config

// The one open context menu, drawn by modules/menu so it follows Theme.
// Either a tray item's DBus menu (handle) or a plain list of items:
//   { text, enabled?, checked?, separator?, action }
Singleton {
    id: root

    property var handle: null
    property var items: []
    // Horizontal anchor in screen coordinates; "top" menus hang below the bar,
    // "bottom" menus sit above the dock, centered on anchorX.
    property real anchorX: 0
    property string edge: "top"
    // Extra space to leave below "bottom" menus.
    property real bottomInset: 0

    function openTray(menuHandle, screen, x) {
        handle = menuHandle;
        items = [];
        show(screen, x, "top");
    }

    function open(menuItems, screen, x, menuEdge, inset) {
        handle = null;
        items = menuItems;
        bottomInset = inset ?? 0;
        show(screen, x, menuEdge ?? "top");
    }

    function show(screen, x, menuEdge) {
        anchorX = x;
        edge = menuEdge;
        Panels.open("menu", screen);
    }

    function close() {
        if (Panels.current === "menu")
            Panels.close();
    }
}
