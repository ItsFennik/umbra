import QtQuick
import Quickshell.Bluetooth
import qs.config
import qs.services

DetailPage {
    title: "Bluetooth"
    hasSwitch: true
    checked: BluetoothService.enabled
    onToggled: on => BluetoothService.setEnabled(on)

    Text {
        width: parent.width
        visible: !BluetoothService.enabled || BluetoothService.devices.length === 0
        topPadding: 6
        bottomPadding: 6
        text: !BluetoothService.enabled ? "Bluetooth is off." : "No paired devices. Pair new devices from your Bluetooth settings."
        wrapMode: Text.Wrap
        color: Theme.textSecondary
        font { family: Theme.font; pixelSize: 12 }
    }

    Repeater {
        model: BluetoothService.enabled ? BluetoothService.devices : []

        delegate: ListItem {
            required property var modelData
            width: parent.width
            icon: modelData.icon?.includes("audio") || modelData.icon?.includes("headset") ? "headphones" : "bluetooth"
            text: modelData.name
            selected: modelData.connected
            detail: modelData.state === BluetoothDeviceState.Connecting ? "Connecting…" : modelData.batteryAvailable ? Math.round(modelData.battery * 100) + "%" : ""
            onClicked: BluetoothService.toggleDevice(modelData)
        }
    }
}
