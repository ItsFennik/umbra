import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.config
import qs.services

// Wallpaper on the background layer of every screen, cross-fading on change.
//   qs -p <umbra dir> ipc call wallpaper set /path/to/image.jpg
//   qs -p <umbra dir> ipc call wallpaper get
//   qs -p <umbra dir> ipc call wallpaper pick
//   qs -p <umbra dir> ipc call colors toggle    (matugen wallpaper colors)
Scope {
    IpcHandler {
        target: "wallpaper"

        function set(path: string): void { Wallpaper.set(path); }
        function get(): string { return Wallpaper.path; }
        function pick(): void { Panels.toggle("wallpaper"); }
    }

    IpcHandler {
        target: "colors"

        function toggle(): void { Matugen.setEnabled(!Matugen.enabled); }
        function enable(): void { Matugen.setEnabled(true); }
        function disable(): void { Matugen.setEnabled(false); }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: window

            required property ShellScreen modelData
            screen: modelData

            anchors { top: true; bottom: true; left: true; right: true }
            exclusionMode: ExclusionMode.Ignore
            color: "black"

            WlrLayershell.namespace: "umbra-wallpaper"
            WlrLayershell.layer: WlrLayer.Background

            // The incoming image loads in the hidden slot, then fades in over the current one.
            property Image front: a

            Connections {
                target: Wallpaper
                function onPathChanged() {
                    (window.front === a ? b : a).source = Wallpaper.path;
                }
            }

            // Right-click the desktop to add widgets or change the wallpaper.
            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.RightButton
                onPressed: mouse => ContextMenu.openAt([
                    ...Widgets.types.map(t => ({ text: "Add " + t.text + " Widget", action: () => Widgets.add(t.id, window.screen, mouse.x, mouse.y) })),
                    { separator: true },
                    { text: "Change Wallpaper…", action: () => Panels.open("wallpaper", window.screen) },
                    { text: "Umbra Settings…", action: () => Settings.windowOpen = true }
                ], window.screen, mouse.x, mouse.y)
            }

            WallpaperImage { id: a; source: Wallpaper.path }
            WallpaperImage { id: b }

            component WallpaperImage: Image {
                id: image
                anchors.fill: parent
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                cache: false
                sourceSize: Qt.size(window.screen.width, window.screen.height)
                opacity: window.front === image ? 1 : 0
                onStatusChanged: {
                    if (status === Image.Ready && source.toString() === Qt.resolvedUrl(Wallpaper.path).toString())
                        window.front = image;
                    else if (status === Image.Error)
                        console.warn("Umbra: cannot load wallpaper", source);
                }
                Behavior on opacity { NumberAnimation { duration: Theme.ms(400); easing.type: Theme.easing } }
            }
        }
    }
}
