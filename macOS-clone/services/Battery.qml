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
    readonly property bool full: device.state === UPowerDeviceState.FullyCharged
    // Seconds until empty or full; 0 while UPower is still estimating.
    readonly property real timeToEmpty: device.timeToEmpty
    readonly property real timeToFull: device.timeToFull
    readonly property real healthPercentage: device.healthSupported ? device.healthPercentage : 0
}
