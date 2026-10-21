import QtQuick
import qs.components
import qs.config
import qs.services

// Umbra's own fonts: interface family, size, weight, fallback and emoji fonts.
// Everything applies live; hovering a font in a list previews it in the card at the top.
Column {
    id: page

    // Family under the pointer in a picker, and which picker it belongs to.
    property string preview
    property string previewKey
    // Which of the fallback and emoji pickers is open.
    property string expanded

    readonly property string previewFont: preview !== "" && previewKey !== "emojiFont" ? preview : Theme.font
    readonly property string previewEmoji: preview !== "" && previewKey === "emojiFont" ? preview : Theme.emojiFont || Theme.font

    function label(family, automatic) {
        return family !== "" && Theme.installed(family) ? family : automatic;
    }

    spacing: 20

    SettingsGroup {
        title: "Preview"

        Item {
            width: parent.width
            height: sample.implicitHeight + 28

            Column {
                id: sample
                anchors { left: parent.left; right: parent.right; top: parent.top; margins: 14 }
                spacing: 6

                Text {
                    width: parent.width
                    elide: Text.ElideRight
                    text: page.preview !== "" ? "Previewing " + page.preview : "Umbra   ·   Wed 21 Oct   14:02"
                    color: Theme.textSecondary
                    font { family: page.previewFont; pixelSize: Theme.px(11); weight: Theme.weight(Font.Medium) }
                }

                Text {
                    width: parent.width
                    elide: Text.ElideRight
                    text: "The quick brown fox jumps over the lazy dog"
                    color: Theme.text
                    font { family: page.previewFont; pixelSize: Theme.px(17); weight: Theme.weight(Font.DemiBold) }
                }

                Text {
                    width: parent.width
                    wrapMode: Text.WordWrap
                    text: "Menus, notifications, the launcher and widgets all use these fonts. 0123456789 — “quotes”, ½ € → ✓"
                    color: Theme.text
                    font { family: page.previewFont; weight: Theme.fontWeight; pixelSize: Theme.px(13) }
                }

                Text {
                    text: "😀 🎉 ✨ 👍 🌈 ❤️ 🚀 ☕"
                    color: Theme.text
                    font { family: page.previewEmoji; weight: Theme.fontWeight; pixelSize: Theme.px(18) }
                }
            }
        }
    }

    SettingsGroup {
        title: "Interface Font"

        SettingsRow {
            title: "Font"
            subtitle: "Automatic picks the first installed of " + Config.fontFamilies.join(", ")

            Text {
                text: Theme.installed(Settings.fontFamily) ? Settings.fontFamily : Settings.fontFamily !== "" ? Settings.fontFamily + " is not installed" : "Automatic (" + Theme.uiFont + ")"
                color: Theme.textSecondary
                font { family: Theme.font; weight: Theme.fontWeight; pixelSize: Theme.px(12) }
            }
        }

        FontPicker {
            value: Theme.installed(Settings.fontFamily) ? Settings.fontFamily : ""
            automaticText: "Automatic (" + (Theme.fallbackFont || Theme.autoFont) + ")"
            onPicked: family => Settings.set("fontFamily", family)
            onPreviewed: family => { page.preview = family; page.previewKey = "fontFamily"; }
        }

        SettingsRow {
            title: "Size"
            subtitle: Theme.fontSize + " px; the default is 13"

            SettingsSlider {
                from: 10
                to: 18
                stepSize: 1
                minLabel: "Smaller"
                maxLabel: "Larger"
                value: Theme.fontSize
                onMoved: v => Settings.set("fontSize", Math.round(v))
            }
        }

        SettingsRow {
            title: "Weight"

            Segmented {
                options: [{ value: 300, text: "Light" }, { value: 400, text: "Regular" }, { value: 500, text: "Medium" }, { value: 600, text: "Semibold" }]
                value: Theme.fontWeight
                onPicked: v => Settings.set("fontWeight", v)
            }
        }
    }

    SettingsGroup {
        title: "Fallback & Emoji"
        footer: "Characters a font lacks are filled in per character by fontconfig, as in other apps."

        SettingsRow {
            title: "Fallback font"
            subtitle: "Used when the interface font is not installed, e.g. after applying a profile made on another machine"
            cursorShape: Qt.PointingHandCursor
            onClicked: page.expanded = page.expanded === "fallbackFont" ? "" : "fallbackFont"

            Row {
                spacing: 6

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: page.label(Settings.fallbackFont, "None")
                    color: Theme.textSecondary
                    font { family: Theme.font; weight: Theme.fontWeight; pixelSize: Theme.px(12) }
                }

                Icon {
                    anchors.verticalCenter: parent.verticalCenter
                    name: "chevron-right"
                    size: 12
                    rotation: page.expanded === "fallbackFont" ? 90 : 0
                    color: Theme.textSecondary
                }
            }
        }

        FontPicker {
            visible: page.expanded === "fallbackFont"
            value: Theme.fallbackFont
            automaticText: "None"
            onPicked: family => Settings.set("fallbackFont", family)
            onPreviewed: family => { page.preview = family; page.previewKey = "fallbackFont"; }
        }

        SettingsRow {
            title: "Emoji font"
            subtitle: "For emoji Umbra draws itself, like e> in the launcher"
            cursorShape: Qt.PointingHandCursor
            onClicked: page.expanded = page.expanded === "emojiFont" ? "" : "emojiFont"

            Row {
                spacing: 6

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: page.label(Settings.emojiFont, Theme.emojiFont !== "" ? "Automatic (" + Theme.emojiFont + ")" : "None installed")
                    color: Theme.textSecondary
                    font { family: Theme.font; weight: Theme.fontWeight; pixelSize: Theme.px(12) }
                }

                Icon {
                    anchors.verticalCenter: parent.verticalCenter
                    name: "chevron-right"
                    size: 12
                    rotation: page.expanded === "emojiFont" ? 90 : 0
                    color: Theme.textSecondary
                }
            }
        }

        FontPicker {
            visible: page.expanded === "emojiFont"
            // Color and emoji fonts first; any font can still be found by searching.
            families: Theme.installedFonts.filter(f => /emoji|symbol|twemoji|joypixels/i.test(f))
            automaticText: "Automatic (" + (Config.emojiFamilies.find(f => Theme.installedFonts.includes(f)) ?? "none installed") + ")"
            value: Theme.installed(Settings.emojiFont) ? Settings.emojiFont : ""
            onPicked: family => Settings.set("emojiFont", family)
            onPreviewed: family => { page.preview = family; page.previewKey = "emojiFont"; }
        }
    }

    Item {
        width: parent.width
        height: reset.height

        Text {
            anchors { left: parent.left; right: reset.left; rightMargin: 12; verticalCenter: parent.verticalCenter }
            leftPadding: 4
            wrapMode: Text.WordWrap
            text: "These fonts apply only to Umbra. System and app fonts (GTK, Qt, fontconfig) are not changed."
            color: Theme.textSecondary
            font { family: Theme.font; weight: Theme.fontWeight; pixelSize: Theme.px(11) }
        }

        PushButton {
            id: reset
            anchors.right: parent.right
            text: "Reset Fonts"
            onClicked: Settings.reset(Settings.fontKeys)
        }
    }
}
