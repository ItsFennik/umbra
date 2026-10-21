import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import qs.config
import qs.services

// Spotlight-style app search. Toggle from a compositor keybind with:
//   qs -p <umbra dir> ipc call launcher toggle
Scope {
    IpcHandler {
        target: "launcher"

        function toggle(): void { Panels.toggle("launcher"); }
        function open(): void { Panels.open("launcher"); }
        function close(): void { Panels.close(); }
    }

    LazyLoader {
        active: Panels.current === "launcher"

        PanelWindow {
            id: window

            screen: Compositor.focusedScreen ?? Quickshell.screens[0]
            anchors { top: true; bottom: true; left: true; right: true }
            exclusionMode: ExclusionMode.Ignore
            color: "transparent"

            WlrLayershell.namespace: "umbra-launcher"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
            BackgroundEffect.blurRegion: Region { item: panel }

            property var results: Apps.search(field.text, 8)
            property int selected: 0
            onResultsChanged: selected = 0

            function launch(entry) {
                if (!entry)
                    return;
                entry.execute();
                Panels.close();
            }

            // Clicking anywhere outside the panel dismisses it.
            MouseArea {
                anchors.fill: parent
                onClicked: Panels.close()
            }

            Rectangle {
                id: panel

                x: (parent.width - width) / 2
                y: Math.round(parent.height * 0.22)
                width: 640
                height: column.implicitHeight
                radius: 14
                color: Theme.popupBackground
                border { width: 1; color: Theme.dockBorder }
                clip: true

                opacity: 0
                scale: 0.98
                Component.onCompleted: { opacity = 1; scale = 1; }
                Behavior on opacity { NumberAnimation { duration: Theme.durationShort } }
                Behavior on scale { NumberAnimation { duration: Theme.durationMedium; easing.type: Theme.easing } }
                Behavior on height { NumberAnimation { duration: Theme.durationShort; easing.type: Theme.easing } }

                // Swallow clicks so they do not reach the dismiss area.
                MouseArea { anchors.fill: parent }

                Column {
                    id: column
                    width: parent.width

                    Item {
                        width: parent.width
                        height: 52

                        SearchGlyph {
                            id: glyph
                            anchors { left: parent.left; leftMargin: 18; verticalCenter: parent.verticalCenter }
                        }

                        TextInput {
                            id: field
                            anchors { left: glyph.right; leftMargin: 12; right: parent.right; rightMargin: 18; verticalCenter: parent.verticalCenter }
                            focus: true
                            color: Theme.text
                            selectionColor: Theme.accent
                            selectedTextColor: Theme.onAccent
                            font { family: Theme.font; pixelSize: 20 }

                            Keys.onEscapePressed: Panels.close()
                            Keys.onReturnPressed: window.launch(window.results[window.selected])
                            Keys.onEnterPressed: window.launch(window.results[window.selected])
                            Keys.onUpPressed: window.selected = Math.max(0, window.selected - 1)
                            Keys.onDownPressed: window.selected = Math.min(window.results.length - 1, window.selected + 1)
                            Keys.onTabPressed: window.selected = (window.selected + 1) % Math.max(1, window.results.length)

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                visible: field.text === ""
                                text: "Search applications"
                                color: Theme.textSecondary
                                font: field.font
                            }
                        }
                    }

                    Rectangle {
                        visible: window.results.length > 0
                        width: parent.width
                        height: 1
                        color: Theme.hairline
                    }

                    Column {
                        width: parent.width
                        topPadding: window.results.length > 0 ? 6 : 0
                        bottomPadding: window.results.length > 0 ? 6 : 0

                        Repeater {
                            model: window.results

                            delegate: MouseArea {
                                id: row
                                required property var modelData
                                required property int index

                                readonly property bool current: index === window.selected

                                x: 6
                                width: parent.width - 12
                                height: 40
                                hoverEnabled: true
                                onEntered: window.selected = index
                                onClicked: window.launch(modelData)

                                Rectangle {
                                    anchors.fill: parent
                                    radius: 8
                                    color: row.current ? Theme.accent : "transparent"
                                }

                                IconImage {
                                    id: rowIcon
                                    anchors { left: parent.left; leftMargin: 10; verticalCenter: parent.verticalCenter }
                                    implicitSize: 26
                                    source: Apps.iconFor(row.modelData, row.modelData.id)
                                    asynchronous: true
                                    mipmap: true
                                }

                                Text {
                                    id: rowName
                                    anchors { left: rowIcon.right; leftMargin: 12; verticalCenter: parent.verticalCenter }
                                    text: row.modelData.name
                                    color: row.current ? Theme.onAccent : Theme.text
                                    font { family: Theme.font; pixelSize: 14; weight: Font.Medium }
                                }

                                Text {
                                    anchors { left: rowName.right; leftMargin: 10; right: parent.right; rightMargin: 12; baseline: rowName.baseline }
                                    text: row.modelData.genericName || row.modelData.comment
                                    elide: Text.ElideRight
                                    color: row.current ? Qt.rgba(1, 1, 1, 0.75) : Theme.textSecondary
                                    font { family: Theme.font; pixelSize: 12 }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
