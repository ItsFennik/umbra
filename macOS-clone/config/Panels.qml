pragma Singleton
import QtQuick
import Quickshell

// Which transient panel is open, and on which screen. Opening one closes the others.
Singleton {
    property string current: ""
    property var screen: null

    function toggle(name, onScreen) {
        if (current === name) {
            current = "";
        } else {
            screen = onScreen ?? null;
            current = name;
        }
    }

    function open(name, onScreen) {
        screen = onScreen ?? null;
        current = name;
    }

    function close() {
        current = "";
    }
}
