import QtQuick
import qs.config
import qs.modules.widgets

// Frameless spectrum over the wallpaper.
WidgetBase {
    id: root

    Spectrum {
        anchors.fill: parent
        bars: Math.round(root.options.bars ?? 56)
        spacing: Math.max(2, Math.min(4, root.width / bars * 0.35))
        minLength: 4
        color: root.options.color === "white" ? "white" : root.options.color === "text" ? Theme.text : Theme.accent
        centered: root.options.centered ?? true
        mirrored: root.options.mirrored ?? true
        fadeEdges: true
    }
}
