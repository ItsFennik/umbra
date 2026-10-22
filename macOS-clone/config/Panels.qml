pragma Singleton
import QtQuick
import Quickshell

// Which transient panel is open, and on which screen. Opening one closes the others.
Singleton {
    property string current: ""
    property var screen: null
    // Horizontal centre of the item that opened the panel, in screen coordinates; -1 when unknown.
    property real anchorX: -1

    function toggle(name, onScreen, x) {
        if (current === name) {
            current = "";
        } else {
            open(name, onScreen, x);
        }
    }

    function open(name, onScreen, x) {
        screen = onScreen ?? null;
        anchorX = x ?? -1;
        current = name;
    }

    function close() {
        current = "";
    }
}
