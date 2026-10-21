import QtQuick
import Quickshell
import qs.components
import qs.config
import qs.services

// Desktop widgets: add any registered type, restack, configure and remove placed ones.
Column {
    id: widgetsPage

    // Placed widget whose options are open; "Widget Settings…" on the desktop opens one here.
    property string expanded: Settings.widgetFocus
    // Restacking: index being dragged and where it would land, or -1.
    property int dragFrom: -1
    property int dropIndex: -1

    function indexAt(column, y) {
        let count = 0;
        for (let i = 0; i < column.children.length; i++) {
            const c = column.children[i];
            if (c.isEntry !== true)
                continue;
            count++;
            if (y < c.y + c.height / 2)
                return c.index;
        }
        return count;
    }

    function drop() {
        if (dragFrom >= 0 && dropIndex >= 0)
            Widgets.reorder(dragFrom, dropIndex > dragFrom ? dropIndex - 1 : dropIndex);
        dragFrom = -1;
        dropIndex = -1;
    }

    Component.onDestruction: Settings.widgetFocus = ""

    spacing: 20

    SettingsGroup {
        title: "On Your Desktop"
        footer: Widgets.list.length > 1 ? "Drag a widget by its grip to restack it; the last one is in front." : ""

        SettingsRow {
            visible: Widgets.list.length === 0
            title: "No widgets yet"
            subtitle: "Add one below, or right-click the wallpaper"
        }

        Repeater {
            model: ScriptModel { values: Widgets.list.map(w => w.id) }

            delegate: WidgetEntry {
                page: widgetsPage
            }
        }
    }

    SettingsGroup {
        title: "Add Widgets"
        footer: "Each folder in modules/widgets with a manifest.json and a Widget.qml is a widget type and shows up here on its own."

        SettingsRow {
            visible: Widgets.scanned && Widgets.types.length === 0
            title: "No widget types found"
            subtitle: Widgets.directory
        }

        Repeater {
            model: Widgets.types

            delegate: SettingsRow {
                id: typeRow
                required property var modelData

                title: modelData.text
                subtitle: modelData.description

                PushButton {
                    text: "Add"
                    onClicked: Widgets.add(typeRow.modelData.id, Compositor.focusedScreen ?? Quickshell.screens[0])
                }
            }
        }
    }

    Item {
        width: parent.width
        height: clear.height

        PushButton {
            anchors.left: parent.left
            text: "Rescan Widget Types"
            onClicked: Widgets.reload()
        }

        PushButton {
            id: clear
            anchors.right: parent.right
            text: "Remove All Widgets"
            enabled: Widgets.list.length > 0
            onClicked: Widgets.clear()
        }
    }
}
