pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.UPower

// Laptop battery through UPower; `available` is false on machines without one.
Singleton {
    readonly property var device: UPower.displayDevice
    readonly property bool available: device.isPresent && device.isLaptopBattery
    readonly property real percentage: device.percentage
    readonly property bool charging: device.state === UPowerDeviceState.Charging || device.state === UPowerDeviceState.FullyCharged
}
