import QtQuick
import qs.config

// Rounded glass card behind framed widgets; the blur comes from WidgetFrame when the type has "glass".
Rectangle {
    anchors.fill: parent
    radius: 22
    color: Theme.popupBackground
    border { width: 1; color: Theme.dockBorder }
}
