import QtQuick
import Quickshell.Widgets
import qs.components
import qs.config
import qs.services

// Round user picture from ~/.face, or the user glyph when there is none.
ClippingRectangle {
    id: root

    property int size: 36

    implicitWidth: size
    implicitHeight: size
    radius: size / 2
    color: Theme.tileOff

    Icon {
        anchors.centerIn: parent
        visible: face.status !== Image.Ready
        name: "user"
        size: root.size * 0.55
        color: Theme.textSecondary
    }

    Image {
        id: face
        anchors.fill: parent
        source: User.hasFace ? "file://" + User.facePath + "?v=" + User.revision : ""
        sourceSize { width: root.size * 2; height: root.size * 2 }
        fillMode: Image.PreserveAspectCrop
        cache: false
        asynchronous: true
    }
}
