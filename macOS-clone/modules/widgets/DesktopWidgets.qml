import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.config
import qs.services

// Desktop widgets: one transparent layer per screen, between the wallpaper and windows.
// Input only reaches the widgets themselves; the rest falls through to the wallpaper.
// Drag a widget to move it, drag its corner to resize it, right-click it for its menu.
// Right-click the wallpaper to add one; Settings > Widgets lists, orders and configures them.
//   qs -p <umbra dir> ipc call widgets add <type>       (see `widgets types`)
//   qs -p <umbra dir> ipc call widgets clear
//   qs -p <umbra dir> ipc call widgets reload           (rescans modules/widgets for new types)
Scope {
    IpcHandler {
        target: "widgets"

        function add(type: string): void { Widgets.add(type, Compositor.focusedScreen); }
        function clear(): void { Widgets.clear(); }
        function list(): string { return JSON.stringify(Widgets.list); }
        function types(): string { return Widgets.types.map(t => t.id).join("\n"); }
        function reload(): void { Widgets.reload(); }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: window

            required property ShellScreen modelData
            screen: modelData

            anchors { top: true; bottom: true; left: true; right: true }
            exclusionMode: ExclusionMode.Ignore
            color: "transparent"

            WlrLayershell.namespace: "umbra-widgets"
            WlrLayershell.layer: WlrLayer.Bottom
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

            // Frames register their regions here while they exist.
            property list<Region> inputRegions
            property list<Region> blurRegions

            mask: Region { regions: window.inputRegions }
            BackgroundEffect.blurRegion: Region { regions: Theme.blur ? window.blurRegions : [] }

            Repeater {
                // Sorted ids, so moving or restacking a widget keeps every delegate; z sets the stacking.
                model: ScriptModel { values: Widgets.on(window.screen).map(w => w.id).sort() }

                delegate: WidgetFrame {
                    required property string modelData
                    widgetId: modelData
                    surface: window
                }
            }
        }
    }
}
