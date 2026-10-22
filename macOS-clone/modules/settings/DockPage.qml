import QtQuick
import qs.components
import qs.config
import qs.services

Column {
    spacing: 20

    SettingsGroup {
        title: "Menu Bar"

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

        SettingsRow {
            title: "Show Now Playing"
            subtitle: "Current track with playback controls"

            Switch {
                checked: Settings.barShowMedia
                onToggled: on => Settings.set("barShowMedia", on)
            }
        }
    }

    SettingsGroup {
        title: "Dock"

        SettingsRow {
            title: "Show Dock"

            Switch {
                checked: Settings.showDock
                onToggled: on => Settings.set("showDock", on)
            }
        }

        SettingsRow {
            title: "Size"
            enabled: Settings.showDock

            SettingsSlider {
                from: 32
                to: 80
                stepSize: 2
                minLabel: "Small"
                maxLabel: "Large"
                value: Settings.dockIconSize
                onMoved: v => Settings.set("dockIconSize", Math.round(v))
            }
        }

        SettingsRow {
            title: "Magnification"
            enabled: Settings.showDock

            Row {
                spacing: 14

                SettingsSlider {
                    anchors.verticalCenter: parent.verticalCenter
                    implicitWidth: 180
                    enabled: Settings.dockMagnification
                    from: 1.1
                    to: 2
                    stepSize: 0.05
                    minLabel: "Small"
                    maxLabel: "Large"
                    value: Settings.dockMagnificationScale
                    onMoved: v => Settings.set("dockMagnificationScale", v)
                }

                Switch {
                    anchors.verticalCenter: parent.verticalCenter
                    checked: Settings.dockMagnification
                    onToggled: on => Settings.set("dockMagnification", on)
                }
            }
        }

        SettingsRow {
            title: "Automatically hide and show the Dock"
            enabled: Settings.showDock

            Switch {
                checked: Settings.dockAutoHide
                onToggled: on => Settings.set("dockAutoHide", on)
            }
        }
    }

    SettingsGroup {
        title: "Effects"

        SettingsRow {
            title: "Animate opening applications"
            subtitle: "Icons bounce once when an app launches"
            enabled: Settings.showDock

            Switch {
                checked: Settings.dockAnimateLaunch
                onToggled: on => Settings.set("dockAnimateLaunch", on)
            }
        }

        SettingsRow {
            title: "Show indicators for open applications"
            enabled: Settings.showDock

            Switch {
                checked: Settings.dockShowIndicators
                onToggled: on => Settings.set("dockShowIndicators", on)
            }
        }

        SettingsRow {
            title: "Show open applications not kept in the Dock"
            enabled: Settings.showDock

            Switch {
                checked: Settings.dockShowRunning
                onToggled: on => Settings.set("dockShowRunning", on)
            }
        }
    }
}
