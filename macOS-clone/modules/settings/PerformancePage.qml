import QtQuick
import qs.components
import qs.config
import qs.services

// Animations, blur and transparency, each with a cheaper fallback when off.
Column {
    spacing: 20

    SettingsGroup {
        title: "Effects"
        footer: "Each switch is independent and applies right away. Turning effects off lowers GPU work, which helps on battery and older hardware."

        SettingsRow {
            title: "Animations"
            subtitle: "Fades, slides and the Dock bounce; off changes instantly"

            Switch {
                checked: Settings.animations
                onToggled: on => Settings.set("animations", on)
            }
        }

        SettingsRow {
            title: "Blur"
            subtitle: "Blurs what is behind the bar, Dock, menus and glass widgets; off uses denser tints instead. Needs compositor support"

            Switch {
                checked: Settings.blur
                onToggled: on => Settings.set("blur", on)
            }
        }

        SettingsRow {
            title: "Transparency"
            subtitle: "Translucent surfaces; off makes them solid"

            Switch {
                checked: Settings.transparency
                onToggled: on => Settings.set("transparency", on)
            }
        }
    }

    SettingsGroup {
        title: "Presets"

        SettingsRow {
            title: "Lightweight"
            subtitle: "Turns all three off"

            PushButton {
                text: "Apply"
                enabled: Settings.animations || Settings.blur || Settings.transparency
                onClicked: Settings.setMany({ animations: false, blur: false, transparency: false })
            }
        }

        SettingsRow {
            title: "Full effects"
            subtitle: "Turns all three back on"

            PushButton {
                text: "Apply"
                enabled: !(Settings.animations && Settings.blur && Settings.transparency)
                onClicked: Settings.setMany({ animations: true, blur: true, transparency: true })
            }
        }
    }
}
