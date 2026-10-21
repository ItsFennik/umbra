import QtQuick
import qs.components
import qs.config
import qs.services

// One placed desktop widget in Settings > Widgets. Drag the grip to restack it; its settings,
// generated from the type's manifest, open below it.
Column {
    id: entry

    // The widget's id; rows are keyed by id so saving a setting keeps them in place.
    required property string modelData
    required property var page

    readonly property bool isEntry: true
    readonly property var widget: Widgets.entry(modelData) ?? {}
    readonly property int index: Widgets.list.findIndex(w => w.id === modelData)
    readonly property var type: Widgets.type(widget.type)
    readonly property var options: Widgets.optionsFor(widget)
    readonly property var size: Widgets.sizeOf(widget)
    readonly property bool expanded: page.expanded === modelData
    readonly property bool front: index === Widgets.list.length - 1

    width: parent.width

    Item {
        width: parent.width
        height: 50

        Rectangle {
            visible: entry.y > 0
            anchors { left: parent.left; right: parent.right; top: parent.top; leftMargin: 12; rightMargin: 12 }
            height: 1
            color: Theme.hairline
        }

        // Drop position while restacking.
        Rectangle {
            visible: entry.page.dragFrom >= 0 && (entry.page.dropIndex === entry.index || (entry.front && entry.page.dropIndex === entry.index + 1))
            anchors { left: parent.left; right: parent.right; leftMargin: 8; rightMargin: 8 }
            y: entry.page.dropIndex === entry.index ? -1 : entry.height - 1
            height: 2
            radius: 1
            color: Theme.accent
            z: 2
        }

        MouseArea {
            id: grip
            anchors { left: parent.left; leftMargin: 6; verticalCenter: parent.verticalCenter }
            width: 22
            height: 34
            enabled: Widgets.list.length > 1
            preventStealing: true
            cursorShape: pressed ? Qt.ClosedHandCursor : enabled ? Qt.OpenHandCursor : Qt.ArrowCursor
            onPressed: entry.page.dragFrom = entry.index
            onPositionChanged: mouse => entry.page.dropIndex = entry.page.indexAt(entry.parent, mapToItem(entry.parent, mouse.x, mouse.y).y)
            onReleased: entry.page.drop()

            Icon {
                anchors.centerIn: parent
                name: "grip"
                size: 16
                strokeWidth: 2.6
                color: grip.enabled ? Theme.textSecondary : Theme.hairline
            }
        }

        Rectangle {
            id: badge
            anchors { left: grip.right; leftMargin: 6; verticalCenter: parent.verticalCenter }
            width: 26
            height: 26
            radius: 7
            color: entry.type ? Theme.accent : Theme.tileOff

            Icon {
                anchors.centerIn: parent
                name: entry.type?.icon ?? "x"
                size: 14
                color: entry.type ? Theme.onAccent : Theme.textSecondary
            }
        }

        Column {
            anchors { left: badge.right; leftMargin: 10; right: buttons.left; rightMargin: 10; verticalCenter: parent.verticalCenter }
            spacing: 2

            Text {
                width: parent.width
                elide: Text.ElideRight
                text: entry.type?.text ?? "“" + entry.widget.type + "” (not installed)"
                color: Theme.text
                font { family: Theme.font; weight: Theme.fontWeight; pixelSize: Theme.px(13) }
            }

            Text {
                width: parent.width
                elide: Text.ElideRight
                text: [entry.widget.screen, entry.type ? entry.size.width + " × " + entry.size.height : "", entry.front && Widgets.list.length > 1 ? "in front" : ""].filter(s => s).join(" · ")
                color: Theme.textSecondary
                font { family: Theme.font; weight: Theme.fontWeight; pixelSize: Theme.px(11) }
            }
        }

        Row {
            id: buttons
            anchors { right: parent.right; rightMargin: 12; verticalCenter: parent.verticalCenter }
            spacing: 6

            PushButton {
                visible: entry.type !== null
                text: entry.expanded ? "Done" : "Options"
                onClicked: entry.page.expanded = entry.expanded ? "" : entry.modelData
            }

            PushButton {
                text: "Remove"
                onClicked: Widgets.remove(entry.modelData)
            }
        }
    }

    Rectangle {
        visible: entry.expanded
        width: parent.width
        height: options.implicitHeight
        color: Theme.dark ? Qt.rgba(0, 0, 0, 0.16) : Qt.rgba(0, 0, 0, 0.03)

        Column {
            id: options
            width: parent.width

            Repeater {
                model: entry.expanded ? entry.type?.settings ?? [] : []

                delegate: SettingsRow {
                    id: row
                    required property var modelData
                    readonly property var value: entry.options[modelData.key]

                    function set(v) {
                        Widgets.configure(entry.modelData, modelData.key, v);
                    }

                    title: modelData.label
                    leftPadding: 24

                    Loader {
                        sourceComponent: ({ bool: toggle, range: slider, choice: choice, text: field })[row.modelData.type] ?? null

                        Component {
                            id: toggle
                            Switch {
                                checked: row.value === true
                                onToggled: on => row.set(on)
                            }
                        }

                        Component {
                            id: slider
                            Row {
                                spacing: 10

                                SettingsSlider {
                                    anchors.verticalCenter: parent.verticalCenter
                                    implicitWidth: 180
                                    from: row.modelData.from ?? 0
                                    to: row.modelData.to ?? 100
                                    stepSize: row.modelData.step ?? 1
                                    value: Number(row.value)
                                    onMoved: v => row.set(v)
                                }

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 40
                                    text: row.value + (row.modelData.unit ?? "")
                                    color: Theme.textSecondary
                                    font { family: Theme.font; weight: Theme.fontWeight; pixelSize: Theme.px(12); features: { "tnum": 1 } }
                                }
                            }
                        }

                        Component {
                            id: choice
                            Segmented {
                                options: row.modelData.options
                                value: row.value
                                onPicked: v => row.set(v)
                            }
                        }

                        Component {
                            id: field
                            TextField {
                                text: row.value ?? ""
                                input.onEditingFinished: row.set(text)
                            }
                        }
                    }
                }
            }

            SettingsRow {
                title: "Size and settings"
                subtitle: entry.type?.resizable ? "Drag the widget’s corner on the desktop to resize it; Shift keeps its shape" : ""
                leftPadding: 24

                Row {
                    spacing: 6

                    PushButton {
                        text: "Reset Size"
                        enabled: entry.type?.resizable && entry.widget.width !== undefined
                        onClicked: Widgets.resetSize(entry.modelData)
                    }

                    PushButton {
                        text: "Reset Settings"
                        enabled: Object.keys(entry.widget.options ?? {}).length > 0
                        onClicked: Widgets.resetOptions(entry.modelData)
                    }
                }
            }
        }
    }
}
