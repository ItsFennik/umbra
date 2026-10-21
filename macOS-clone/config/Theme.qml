pragma Singleton
import QtQuick
import Quickshell
import qs.services

Singleton {
    readonly property bool dark: Appearance.dark

    // Typography
    readonly property string font: {
        const installed = Qt.fontFamilies();
        return Config.fontFamilies.find(f => installed.includes(f)) ?? "sans-serif";
    }
    readonly property int fontSize: 13

    // Colors. With Matugen on, wallpaper colors replace the base tints but keep their alpha.
    readonly property bool matugen: Matugen.active
    function m(role, fallback, alpha) {
        if (!matugen || !Matugen.colors[role])
            return fallback;
        const c = Qt.color(Matugen.colors[role]);
        return alpha === undefined ? c : Qt.rgba(c.r, c.g, c.b, alpha);
    }

    readonly property color text: m("on_surface", dark ? "#f5f5f7" : "#1d1d1f")
    readonly property color textSecondary: m("on_surface_variant", dark ? Qt.rgba(235 / 255, 235 / 255, 245 / 255, 0.6) : Qt.rgba(60 / 255, 60 / 255, 67 / 255, 0.6), 0.75)
    readonly property color accent: m("primary", dark ? "#0a84ff" : "#007aff")
    readonly property color onAccent: m("on_primary", "white")
    readonly property color hairline: dark ? Qt.rgba(1, 1, 1, 0.1) : Qt.rgba(0, 0, 0, 0.08)
    readonly property color hover: dark ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(0, 0, 0, 0.08)

    // Tints are opaque enough to stay legible when the compositor provides no blur.
    readonly property color barBackground: m("surface", dark ? Qt.rgba(22 / 255, 22 / 255, 24 / 255, 0.62) : Qt.rgba(246 / 255, 246 / 255, 248 / 255, 0.66), dark ? 0.62 : 0.66)
    readonly property color dockBackground: m("surface_container", dark ? Qt.rgba(36 / 255, 36 / 255, 40 / 255, 0.58) : Qt.rgba(246 / 255, 246 / 255, 248 / 255, 0.6), dark ? 0.58 : 0.6)
    readonly property color dockBorder: m("outline_variant", dark ? Qt.rgba(1, 1, 1, 0.14) : Qt.rgba(0, 0, 0, 0.1), 0.5)
    readonly property color indicator: m("on_surface", dark ? Qt.rgba(1, 1, 1, 0.8) : Qt.rgba(0, 0, 0, 0.6), dark ? 0.8 : 0.6)
    readonly property color popupBackground: m("surface_container", dark ? Qt.rgba(30 / 255, 30 / 255, 34 / 255, 0.84) : Qt.rgba(250 / 255, 250 / 255, 252 / 255, 0.86), dark ? 0.84 : 0.86)
    readonly property color tooltipBackground: m("surface_container_high", dark ? Qt.rgba(40 / 255, 40 / 255, 44 / 255, 0.92) : Qt.rgba(250 / 255, 250 / 255, 252 / 255, 0.94), dark ? 0.92 : 0.94)

    readonly property color moduleBackground: dark ? Qt.rgba(1, 1, 1, 0.07) : Qt.rgba(1, 1, 1, 0.55)
    readonly property color tileOff: dark ? Qt.rgba(1, 1, 1, 0.14) : Qt.rgba(0, 0, 0, 0.08)
    readonly property color sliderTrack: dark ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(0, 0, 0, 0.08)
    readonly property color sliderFill: dark ? Qt.rgba(1, 1, 1, 0.92) : "#ffffff"
    readonly property color sliderKnob: "#ffffff"
    readonly property color sliderIcon: Qt.rgba(0, 0, 0, 0.55)
    readonly property color destructive: m("error", dark ? "#ff453a" : "#ff3b30")

    // Metrics
    readonly property int barHeight: 28
    readonly property int dockIconSize: Settings.dockIconSize
    readonly property int dockPadding: 6
    readonly property int dockSpacing: 4
    readonly property int dockRadius: 16
    readonly property int dockMargin: 6
    readonly property int radiusSmall: 6
    readonly property int radiusMedium: 10
    readonly property int radiusLarge: 14
    readonly property int panelGap: 8

    // Motion
    readonly property int durationShort: 120
    readonly property int durationMedium: 200
    readonly property int easing: Easing.OutCubic
}
