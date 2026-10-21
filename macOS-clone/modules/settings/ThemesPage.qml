import QtQuick
import qs.components
import qs.config
import qs.services

Column {
    spacing: 20

    SettingsGroup {
        title: "Wallpaper Colors"
        footer: Matugen.available ? "Writes the matugen palette of the wallpaper into ~/.config/gtk-3.0 and gtk-4.0/gtk.css as accent, window and sidebar colors. Works best with adw-gtk3; GTK 3 apps update right away, GTK 4 apps when reopened." : ""

        SettingsRow {
            title: "Wallpaper Colors in Apps"
            subtitle: Matugen.available ? "GTK apps follow the wallpaper and Light/Dark" : "Install matugen to enable"
            enabled: Matugen.available

            Switch {
                checked: Settings.gtkMatugen
                onToggled: on => Settings.set("gtkMatugen", on)
            }
        }

        SettingsRow {
            title: "Palette"
            visible: GtkTheme.colorsActive

            Row {
                spacing: 6

                Repeater {
                    model: ["primary", "secondary", "tertiary", "surface_container", "on_surface"]

                    delegate: Rectangle {
                        required property string modelData
                        width: 18
                        height: 18
                        radius: 9
                        color: GtkTheme.palette[modelData] ?? "transparent"
                        border { width: 1; color: Theme.hairline }
                    }
                }
            }
        }
    }

    SettingsGroup {
        title: "GTK Theme"
        footer: "Themes with a dark variant, like adw-gtk3 and adw-gtk3-dark, switch with Light/Dark in Appearance."

        Repeater {
            model: GtkTheme.families

            delegate: SettingsRow {
                id: row
                required property var modelData
                readonly property bool current: GtkTheme.family?.name === modelData.name

                title: modelData.name
                subtitle: modelData.light && modelData.dark ? "Light and Dark" : modelData.dark ? "Dark only" : "Light only"
                cursorShape: Qt.PointingHandCursor
                onClicked: GtkTheme.setFamily(modelData)

                Icon {
                    visible: row.current
                    name: "check"
                    size: 14
                    color: Theme.accent
                }
            }
        }
    }
}
