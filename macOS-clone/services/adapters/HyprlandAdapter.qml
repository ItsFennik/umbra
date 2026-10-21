import QtQuick
import Quickshell
import Quickshell.Hyprland

// Hyprland IPC adapter: adds the window -> workspace mapping that the
// foreign-toplevel and ext-workspace protocols do not provide, and a clean logout.
QtObject {
    readonly property var toplevels: Hyprland.toplevels.values

    function workspaceNameOf(window) {
        return toplevels.find(t => t.wayland === window)?.workspace?.name ?? null;
    }

    function logout() {
        Hyprland.dispatch("exit");
    }
}
