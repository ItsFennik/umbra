pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Bluetooth

// BlueZ adapter state. `available` is false without an adapter.
Singleton {
    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool available: adapter !== null && adapter.state !== BluetoothAdapterState.Blocked
    readonly property bool enabled: adapter?.enabled ?? false
    readonly property var devices: (adapter?.devices.values ?? []).filter(d => d.paired || d.connected)
        .sort((a, b) => (b.connected - a.connected) || a.name.localeCompare(b.name))
    readonly property var connected: devices.filter(d => d.connected)

    readonly property string status: {
        if (!available)
            return "Unavailable";
        if (!enabled)
            return "Off";
        if (connected.length === 1)
            return connected[0].name;
        return connected.length > 1 ? connected.length + " Devices" : "On";
    }

    function setEnabled(on) {
        if (adapter)
            adapter.enabled = on;
    }

    function toggleDevice(device) {
        device.connected ? device.disconnect() : device.connect();
    }
}
