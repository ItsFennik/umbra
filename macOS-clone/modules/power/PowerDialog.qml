import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.components
import qs.config
import qs.modules.settings
import qs.services

// Power menu and macOS-style shutdown alert. With no action it shows a menu of every
// option (arrows, Enter or the hinted letter pick one); confirming restart, shut down
// or log out counts down and runs the action on its own.
//   qs -p <umbra dir> ipc call power toggle
//   qs -p <umbra dir> ipc call power <restart|shutdown|logout|sleep|lock>
Scope {
    IpcHandler {
        target: "power"

        function toggle(): void { Panels.current === "power" ? Panels.close() : Session.request(""); }
        function open(): void { Session.request(""); }
        function close(): void { if (Panels.current === "power") Panels.close(); }
        function restart(): void { Session.request("restart"); }
        function shutdown(): void { Session.request("shutdown"); }
        function logout(): void { Session.request("logout"); }
        function sleep(): void { Session.run("sleep"); }
        function lock(): void { Session.run("lock"); }
    }

    LazyLoader {
        active: Panels.current === "power"

        PanelWindow {
            id: window

            screen: Panels.screen ?? Compositor.focusedScreen ?? Quickshell.screens[0]
            anchors { top: true; bottom: true; left: true; right: true }
            exclusionMode: ExclusionMode.Ignore
            color: "transparent"

            WlrLayershell.namespace: "umbra-power"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
            BackgroundEffect.blurRegion: Region { item: panel }

            readonly property string action: Session.pending
            readonly property var copy: ({
                "restart": { title: "Are you sure you want to restart your computer now?", verb: "Restart", after: "the computer will restart" },
                "shutdown": { title: "Are you sure you want to shut down your computer now?", verb: "Shut Down", after: "the computer will shut down" },
                "logout": { title: "Are you sure you want to quit all applications and log out now?", verb: "Log Out", after: "you will be logged out" }
            })[action] ?? null
            // Restart, shut down and log out confirm first; divider draws a line above the row.
            readonly property var items: [
                { text: "Lock Screen", icon: "lock", action: "lock", key: "L" },
                { text: "Sleep", icon: "moon", action: "sleep", key: "S" },
                { text: "Restart…", icon: "restart", action: "restart", key: "R", confirm: true, divider: true },
                { text: "Shut Down…", icon: "power", action: "shutdown", key: "U", confirm: true },
                { text: "Log Out " + User.name + "…", icon: "log-out", action: "logout", key: "O", confirm: true, divider: true }
            ]
            property int selected: -1
            property int remaining: 60

            function choose(index) {
                const item = items[index];
                if (!item)
                    return;
                if (item.confirm)
                    Session.request(item.action);
                else
                    Session.run(item.action);
            }

            function move(step) {
                selected = selected < 0
                    ? (step > 0 ? 0 : items.length - 1)
                    : (selected + step + items.length) % items.length;
            }

            Timer {
                running: window.copy !== null
                interval: 1000
                repeat: true
                onTriggered: if (--window.remaining <= 0) Session.run(window.action)
            }

            // macOS keeps the alert up until answered; the menu closes on a click outside.
            Rectangle {
                anchors.fill: parent
                color: Qt.rgba(0, 0, 0, 0.18)
                opacity: panel.opacity
                MouseArea {
                    anchors.fill: parent
                    onClicked: if (!window.copy) Panels.close()
                }
            }

            Rectangle {
                id: panel

                anchors.centerIn: parent
                width: window.copy ? 272 : 260
                height: window.copy ? content.implicitHeight + 32 : menu.implicitHeight + 12
                radius: 16
                color: Theme.popupBackground
                border { width: 1; color: Theme.dockBorder }

                opacity: 0
                scale: 0.94
                Component.onCompleted: { opacity = 1; scale = 1; }
                Behavior on opacity { NumberAnimation { duration: Theme.durationShort } }
                Behavior on scale { NumberAnimation { duration: Theme.durationMedium; easing.type: Easing.OutBack; easing.overshoot: 1.4 } }

                focus: true
                Keys.onEscapePressed: Panels.close()
                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                        window.copy ? Session.run(window.action) : window.choose(window.selected);
                    } else if (window.copy) {
                        return;
                    } else if (event.key === Qt.Key_Down || event.key === Qt.Key_Tab) {
                        window.move(1);
                    } else if (event.key === Qt.Key_Up || event.key === Qt.Key_Backtab) {
                        window.move(-1);
                    } else {
                        const i = window.items.findIndex(item => item.key === event.text.toUpperCase());
                        if (i < 0)
                            return;
                        window.choose(i);
                    }
                    event.accepted = true;
                }

                Column {
                    id: menu
                    visible: !window.copy
                    anchors { left: parent.left; right: parent.right; top: parent.top; margins: 6 }

                    Row {
                        leftPadding: 8
                        topPadding: 6
                        bottomPadding: 8
                        spacing: 10

                        Avatar {
                            anchors.verticalCenter: parent.verticalCenter
                            size: 30
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: User.name
                            color: Theme.text
                            font { family: Theme.font; pixelSize: 13; weight: Font.Bold }
                        }
                    }

                    Repeater {
                        model: window.items

                        delegate: Column {
                            id: entry
                            required property var modelData
                            required property int index

                            readonly property bool highlighted: window.selected === index

                            width: parent.width

                            Item {
                                visible: entry.index === 0 || (entry.modelData.divider ?? false)
                                width: parent.width
                                height: 9

                                Rectangle {
                                    anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter; margins: 8 }
                                    height: 1
                                    color: Theme.hairline
                                }
                            }

                            MouseArea {
                                width: parent.width
                                height: 30
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onEntered: window.selected = entry.index
                                onExited: if (window.selected === entry.index) window.selected = -1
                                onClicked: window.choose(entry.index)

                                Rectangle {
                                    anchors.fill: parent
                                    radius: 6
                                    color: entry.highlighted ? Theme.accent : "transparent"
                                }

                                Icon {
                                    id: glyph
                                    anchors { left: parent.left; leftMargin: 10; verticalCenter: parent.verticalCenter }
                                    name: entry.modelData.icon
                                    size: 15
                                    color: entry.highlighted ? Theme.onAccent : Theme.text
                                }

                                Text {
                                    anchors { left: glyph.right; leftMargin: 10; right: hint.left; rightMargin: 8; verticalCenter: parent.verticalCenter }
                                    text: entry.modelData.text
                                    elide: Text.ElideRight
                                    color: entry.highlighted ? Theme.onAccent : Theme.text
                                    font { family: Theme.font; pixelSize: 13 }
                                }

                                Text {
                                    id: hint
                                    anchors { right: parent.right; rightMargin: 10; verticalCenter: parent.verticalCenter }
                                    text: entry.modelData.key
                                    color: entry.highlighted ? Theme.onAccent : Theme.textSecondary
                                    font { family: Theme.font; pixelSize: 12 }
                                }
                            }
                        }
                    }
                }

                Column {
                    id: content
                    visible: window.copy !== null
                    anchors { left: parent.left; right: parent.right; top: parent.top; margins: 16 }
                    spacing: 0

                    Item {
                        width: parent.width
                        height: 64

                        Avatar {
                            anchors.horizontalCenter: parent.horizontalCenter
                            visible: window.action === "logout"
                            size: 56
                        }

                        Rectangle {
                            anchors.horizontalCenter: parent.horizontalCenter
                            visible: window.action !== "logout"
                            width: 56
                            height: 56
                            radius: 14
                            gradient: Gradient {
                                GradientStop { position: 0; color: Qt.lighter(Theme.accent, 1.25) }
                                GradientStop { position: 1; color: Theme.accent }
                            }

                            Icon {
                                anchors.centerIn: parent
                                name: "power"
                                size: 28
                                strokeWidth: 2.4
                                color: Theme.onAccent
                            }
                        }
                    }

                    Text {
                        width: parent.width
                        text: window.copy?.title ?? ""
                        wrapMode: Text.Wrap
                        horizontalAlignment: Text.AlignHCenter
                        color: Theme.text
                        font { family: Theme.font; pixelSize: 13; weight: Font.Bold }
                    }

                    Text {
                        width: parent.width
                        topPadding: 6
                        text: `If you do nothing, ${window.copy?.after} automatically in ${window.remaining} second${window.remaining === 1 ? "" : "s"}.`
                        wrapMode: Text.Wrap
                        horizontalAlignment: Text.AlignHCenter
                        color: Theme.textSecondary
                        font { family: Theme.font; pixelSize: 11 }
                    }

                    Item { width: 1; height: 18 }

                    // Primary on the right, Cancel beside it.
                    Grid {
                        width: parent.width
                        columns: 2
                        spacing: 8
                        layoutDirection: Qt.RightToLeft

                        Repeater {
                            model: [{ text: window.copy?.verb ?? "", action: window.action }, { text: "Cancel", action: "" }]

                            delegate: MouseArea {
                                id: button
                                required property var modelData
                                required property int index

                                readonly property bool primary: index === 0

                                width: (parent.width - 8) / 2
                                height: 28
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: modelData.action ? Session.run(modelData.action) : Panels.close()

                                Rectangle {
                                    anchors.fill: parent
                                    radius: 7
                                    color: button.primary ? Theme.accent : Theme.tileOff
                                    border { width: button.primary ? 0 : 1; color: Theme.hairline }

                                    Rectangle {
                                        anchors.fill: parent
                                        radius: parent.radius
                                        color: button.pressed ? Qt.rgba(0, 0, 0, 0.15) : button.containsMouse ? Qt.rgba(1, 1, 1, 0.08) : "transparent"
                                    }
                                }

                                Text {
                                    anchors.centerIn: parent
                                    text: button.modelData.text
                                    color: button.primary ? Theme.onAccent : Theme.text
                                    font { family: Theme.font; pixelSize: 13; weight: button.primary ? Font.Medium : Font.Normal }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
