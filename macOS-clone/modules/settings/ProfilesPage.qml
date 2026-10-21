import QtQuick
import qs.components
import qs.config
import qs.services

// Save the current look and layout under a name, and switch between saved profiles.
Column {
    id: page

    // Profile whose Delete was pressed once; a second press deletes it.
    property string confirmDelete

    function save() {
        if (Profiles.save(name.text))
            name.text = "";
    }

    spacing: 20

    Timer {
        id: confirmTimeout
        interval: 3000
        onTriggered: page.confirmDelete = ""
    }

    SettingsGroup {
        title: "Save Current Setup"
        footer: "A profile keeps every Umbra setting (fonts, Dock, performance), light or dark mode, wallpaper colors, the wallpaper, desktop widgets and Dock pins. Icon and cursor themes are system-wide, so profiles leave them alone."

        SettingsRow {
            title: "Name"

            Row {
                spacing: 6

                TextField {
                    id: name
                    anchors.verticalCenter: parent.verticalCenter
                    implicitWidth: 180
                    placeholder: "e.g. Focus, Evening"
                    onAccepted: page.save()
                }

                PushButton {
                    anchors.verticalCenter: parent.verticalCenter
                    primary: true
                    enabled: name.text.trim() !== ""
                    text: Profiles.find(name.text.trim()) ? "Replace" : "Save"
                    onClicked: page.save()
                }
            }
        }
    }

    SettingsGroup {
        title: "Profiles"

        SettingsRow {
            visible: Profiles.list.length === 0
            title: "No profiles yet"
            subtitle: "Save the current setup above to switch back to it later"
        }

        Repeater {
            model: Profiles.list

            delegate: SettingsRow {
                id: row
                required property var modelData
                readonly property bool active: Profiles.active === modelData.name

                title: modelData.name + (active ? "  ✓" : "")
                subtitle: Profiles.describe(modelData) + (modelData.saved ? " · saved " + Qt.formatDateTime(new Date(modelData.saved), "d MMM, HH:mm") : "")

                Row {
                    spacing: 6

                    PushButton {
                        text: "Apply"
                        primary: !row.active
                        onClicked: Profiles.apply(row.modelData.name)
                    }

                    PushButton {
                        text: "Update"
                        onClicked: Profiles.save(row.modelData.name)
                    }

                    PushButton {
                        text: page.confirmDelete === row.modelData.name ? "Confirm" : "Delete"
                        onClicked: {
                            if (page.confirmDelete === row.modelData.name) {
                                Profiles.remove(row.modelData.name);
                                page.confirmDelete = "";
                            } else {
                                page.confirmDelete = row.modelData.name;
                                confirmTimeout.restart();
                            }
                        }
                    }
                }
            }
        }
    }
}
