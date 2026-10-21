pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Networking

// Wi-Fi and wired state through NetworkManager. `available` is false without a backend.
Singleton {
    id: root

    readonly property bool available: Networking.backend !== NetworkBackendType.None
    readonly property var devices: Networking.devices.values
    readonly property var wifiDevice: devices.find(d => d.type === DeviceType.Wifi) ?? null
    readonly property var wiredDevice: devices.find(d => d.type === DeviceType.Wired) ?? null

    readonly property bool wifiAvailable: wifiDevice !== null && Networking.wifiHardwareEnabled
    readonly property bool wifiEnabled: Networking.wifiEnabled
    readonly property bool wiredConnected: wiredDevice?.connected ?? false
    readonly property var activeNetwork: wifiDevice?.networks.values.find(n => n.connected) ?? null

    readonly property var networks: {
        if (!wifiDevice)
            return [];
        return wifiDevice.networks.values.slice().sort((a, b) => (b.connected - a.connected) || (b.known - a.known) || (b.signalStrength - a.signalStrength));
    }

    readonly property string icon: {
        if (activeNetwork) {
            const s = activeNetwork.signalStrength;
            return s > 0.66 ? "wifi" : s > 0.33 ? "wifi-2" : "wifi-1";
        }
        if (wiredConnected)
            return "ethernet";
        return "wifi-off";
    }

    readonly property string wifiStatus: {
        if (activeNetwork)
            return activeNetwork.name;
        if (!wifiAvailable)
            return "Unavailable";
        return wifiEnabled ? "Not Connected" : "Off";
    }

    function setWifiEnabled(on) {
        Networking.wifiEnabled = on;
    }

    function setScanning(on) {
        if (wifiDevice)
            wifiDevice.scannerEnabled = on;
    }

    function isSecured(network) {
        return network.security !== WifiSecurityType.Open && network.security !== WifiSecurityType.Unknown;
    }

    // Known and open networks connect directly; others need a passphrase.
    function needsPassphrase(network) {
        return !network.known && isSecured(network);
    }
}
