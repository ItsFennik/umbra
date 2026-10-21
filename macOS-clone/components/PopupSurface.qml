import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.config
import qs.services

// Transparent layer over the usable screen area (bars and dock stay reachable).
// Clicking outside the panel content or pressing Escape closes it.
PanelWindow {
    id: root

    required property string panelName

    screen: Panels.screen ?? Compositor.focusedScreen ?? Quickshell.screens[0]
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"

    WlrLayershell.namespace: "umbra-" + panelName
    WlrLayershell.layer: WlrLayer.Overlay
    // OnDemand rather than Exclusive: Hyprland routes all pointer input to a layer
    // holding an exclusive grab, which would make the bar unclickable while open.
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    MouseArea {
        anchors.fill: parent
        onClicked: Panels.close()
    }

    Item {
        focus: true
        Keys.onEscapePressed: Panels.close()
    }
}
