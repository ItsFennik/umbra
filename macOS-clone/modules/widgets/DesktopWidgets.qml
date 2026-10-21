import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.config
import qs.services

// Desktop widgets: one transparent layer per screen, between the wallpaper and windows.
// Input only reaches the widgets themselves; the rest falls through to the wallpaper.
// Drag a widget to move it, right-click it to remove it. Right-click the wallpaper to add one.
//   qs -p <umbra dir> ipc call widgets add music|visualizer|clock
//   qs -p <umbra dir> ipc call widgets clear
Scope {
    IpcHandler {
        target: "widgets"

        function add(type: string): void { Widgets.add(type, Compositor.focusedScreen); }
        function clear(): void { Widgets.clear(); }
        function list(): string { return JSON.stringify(Widgets.list); }
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
            BackgroundEffect.blurRegion: Region { regions: window.blurRegions }

            Repeater {
                // Ids, so moving one widget keeps the others' delegates.
                model: ScriptModel { values: Widgets.on(window.screen).map(w => w.id) }

                delegate: WidgetFrame {
                    required property string modelData
                    widgetId: modelData
                    surface: window
                }
            }
        }
    }
}
