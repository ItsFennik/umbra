import QtQuick
import qs.components
import qs.config
import qs.services

Column {
    spacing: 20

    SettingsGroup {
        title: "Layout"
        footer: "Drag items between zones to rearrange the menu bar. Drop one in Available to hide it."

        BarLayoutEditor {
            width: parent.width
        }
    }

    Row {
        anchors.right: parent.right

        PushButton {
            text: "Reset Layout"
            onClicked: Settings.reset(["barLayout"])
        }
    }

    SettingsGroup {
        title: "Appearance"

        SettingsRow {
            title: "Size"

            SettingsSlider {
                from: 24
                to: 48
                stepSize: 1
                minLabel: "Small"
                maxLabel: "Large"
                value: Settings.barHeight
                onMoved: v => Settings.set("barHeight", Math.round(v))
            }
        }

        SettingsRow {
            title: "Opacity"
            subtitle: Settings.transparency ? "" : "Transparency is off in Performance, so the bar is solid"
            enabled: Settings.transparency

            SettingsSlider {
                from: 0
                to: 1
                stepSize: 0.02
                minLabel: "Clear"
                maxLabel: "Solid"
                value: Settings.barOpacity
                onMoved: v => Settings.set("barOpacity", v)
            }
        }

    }

    SettingsGroup {
        title: "Now Playing"
        footer: "Click the track in the menu bar for the Now Playing popout. It stays while paused."

        SettingsRow {
            title: "Text"

            Segmented {
                options: [{ value: "full", text: "Title & Artist" }, { value: "title", text: "Title" }, { value: "none", text: "Artwork Only" }]
                value: Settings.barMediaText
                onPicked: v => Settings.set("barMediaText", v)
            }
        }

        SettingsRow {
            title: "Size"

            SettingsSlider {
                from: 9
                to: 20
                stepSize: 1
                minLabel: "Small"
                maxLabel: "Large"
                value: Settings.barMediaSize
                onMoved: v => Settings.set("barMediaSize", Math.round(v))
            }
        }

        SettingsRow {
            title: "Text Width"
            subtitle: "Longer titles are cut off with …"
            enabled: Settings.barMediaText !== "none"

            SettingsSlider {
                from: 60
                to: 500
                stepSize: 10
                minLabel: "Short"
                maxLabel: "Long"
                value: Settings.barMediaWidth
                onMoved: v => Settings.set("barMediaWidth", Math.round(v))
            }
        }

    }
}
