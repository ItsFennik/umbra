import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

// Hyprland IPC adapter: adds the window -> workspace mapping that the
// foreign-toplevel and ext-workspace protocols do not provide, and a clean logout.
QtObject {
    readonly property var toplevels: Hyprland.toplevels.values

    function workspaceNameOf(window) {
        return toplevels.find(t => t.wayland === window)?.workspace?.name ?? null;
    }

    // Lua configs only take hl.dsp.* dispatchers; fall back to the legacy name for hyprlang ones.
    function logout() {
        exit.running = true;
    }

    property Process exit: Process {
        command: ["sh", "-c", "case \"$(hyprctl dispatch 'hl.dsp.exit()')\" in ok*) ;; *) hyprctl dispatch exit ;; esac"]
    }
}
