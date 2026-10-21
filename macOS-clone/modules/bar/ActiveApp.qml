import QtQuick
import qs.config
import qs.services

Text {
    text: Apps.nameFor(Compositor.activeWindow)
    visible: text !== ""
    color: Theme.text
    font { family: Theme.font; pixelSize: Theme.fontSize; weight: Font.DemiBold }
}
