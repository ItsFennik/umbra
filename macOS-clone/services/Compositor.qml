pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.WindowManager

// Compositor integration through standard protocols only:
//   windows    -> foreign-toplevel management
//   workspaces -> ext-workspace-v1 (Quickshell.WindowManager)
// Compositor-specific adapters belong here, and only for features these protocols lack.
Singleton {
    id: root

    readonly property list<Toplevel> windows: ToplevelManager.toplevels.values
    readonly property Toplevel activeWindow: ToplevelManager.activeToplevel
    // The output showing the focused window; null when nothing is focused.
    readonly property var focusedScreen: activeWindow?.screens[0] ?? null

    // Protocol presence is not exposed directly; an absent protocol yields no workspaces.
    readonly property bool workspacesAvailable: WindowManager.windowsets.length > 0

    // Optional compositor adapter, created only when its compositor is detected.
    property QtObject adapter: null
    readonly property bool windowWorkspacesAvailable: adapter !== null

    Component.onCompleted: {
        if (Quickshell.env("HYPRLAND_INSTANCE_SIGNATURE"))
            adapter = Qt.createComponent("adapters/HyprlandAdapter.qml").createObject(root);
    }

    // Workspace name a window is on, or null when the compositor cannot tell us.
    function workspaceNameOf(window) {
        return adapter ? adapter.workspaceNameOf(window) : null;
    }

    function workspacesFor(screen) {
        const projection = screen ? WindowManager.screenProjection(screen) : null;
        const sets = (projection ? projection.windowsets : WindowManager.windowsets).filter(w => w.shouldDisplay);
        return sets.sort((a, b) => {
            if (a.coordinates.length && b.coordinates.length)
                return a.coordinates[0] - b.coordinates[0];
            const na = parseInt(a.name), nb = parseInt(b.name);
            return (isNaN(na) || isNaN(nb)) ? a.name.localeCompare(b.name) : na - nb;
        });
    }
}
