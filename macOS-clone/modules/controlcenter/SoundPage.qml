import QtQuick
import qs.components
import qs.config
import qs.services

DetailPage {
    title: "Sound"

    Text {
        width: parent.width
        topPadding: 4
        text: "Output"
        color: Theme.textSecondary
        font { family: Theme.font; pixelSize: 11; weight: Font.DemiBold }
    }

    Repeater {
        model: Audio.sinks

        delegate: ListItem {
            required property var modelData
            width: parent.width
            icon: Audio.deviceName(modelData).toLowerCase().includes("headphone") || Audio.deviceName(modelData).toLowerCase().includes("headset") ? "headphones" : "volume-2"
            text: Audio.deviceName(modelData)
            selected: modelData === Audio.sink
            trailingIcon: modelData === Audio.sink ? "check" : ""
            onClicked: Audio.setOutput(modelData)
        }
    }
}
