import QtQuick
import qs.config

// Frameless spectrum over the wallpaper, bass in the middle.
Item {
    Spectrum {
        anchors.fill: parent
        bars: 56
        spacing: 4
        minLength: 4
        color: Theme.accent
        centered: true
        mirrored: true
        fadeEdges: true
    }
}
