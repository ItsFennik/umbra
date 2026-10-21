import QtQuick
import qs.config

// Key and label in the launcher footer, from a { key, text } model entry.
Row {
    required property var modelData
    spacing: 5

    Text {
        text: parent.modelData.key
        color: Theme.text
        font { family: Theme.font; pixelSize: Theme.px(11); weight: Theme.weight(Font.DemiBold) }
    }

    Text {
        text: parent.modelData.text
        color: Theme.textSecondary
        font { family: Theme.font; weight: Theme.fontWeight; pixelSize: Theme.px(11) }
    }
}
