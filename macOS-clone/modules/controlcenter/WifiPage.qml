import QtQuick
import Quickshell.Networking
import qs.components
import qs.config
import qs.services

DetailPage {
    id: root

    property var passphraseFor: null
    property string error: ""

    title: "Wi-Fi"
    hasSwitch: true
    checked: NetworkService.wifiEnabled
    onToggled: on => NetworkService.setWifiEnabled(on)

    Component.onCompleted: NetworkService.setScanning(true)
    Component.onDestruction: NetworkService.setScanning(false)

    function choose(network) {
        error = "";
        if (network.connected)
            return;
        if (NetworkService.needsPassphrase(network))
            passphraseFor = passphraseFor === network ? null : network;
        else
            network.connect();
    }

    Text {
        width: parent.width
        visible: !NetworkService.wifiAvailable || !NetworkService.wifiEnabled
        topPadding: 6
        bottomPadding: 6
        text: NetworkService.wifiAvailable ? "Wi-Fi is off." : "No Wi-Fi hardware available."
        color: Theme.textSecondary
        font { family: Theme.font; pixelSize: 12 }
    }

    Text {
        width: parent.width
        visible: root.error !== ""
        text: root.error
        color: Theme.destructive
        font { family: Theme.font; pixelSize: 11 }
    }

    Repeater {
        model: NetworkService.wifiEnabled ? NetworkService.networks.slice(0, 10) : []

        delegate: Column {
            id: entry
            required property var modelData
            width: parent.width

            Connections {
                target: entry.modelData
                function onConnectionFailed(reason) {
                    root.error = "Couldn't join “" + entry.modelData.name + "” (" + ConnectionFailReason.toString(reason) + ")";
                }
            }

            ListItem {
                width: parent.width
                icon: entry.modelData.signalStrength > 0.66 ? "wifi" : entry.modelData.signalStrength > 0.33 ? "wifi-2" : "wifi-1"
                text: entry.modelData.name
                selected: entry.modelData.connected
                detail: entry.modelData.stateChanging ? "Connecting…" : ""
                trailingIcon: entry.modelData.connected ? "check" : NetworkService.isSecured(entry.modelData) ? "lock" : ""
                onClicked: root.choose(entry.modelData)
            }

            // Passphrase entry for secured networks that are not yet known.
            Rectangle {
                visible: root.passphraseFor === entry.modelData
                x: 38
                width: parent.width - 44
                height: visible ? 28 : 0
                radius: Theme.radiusSmall
                color: Theme.tileOff

                TextInput {
                    id: passphrase
                    anchors { fill: parent; leftMargin: 8; rightMargin: 8 }
                    verticalAlignment: TextInput.AlignVCenter
                    echoMode: TextInput.Password
                    color: Theme.text
                    font { family: Theme.font; pixelSize: 12 }
                    onVisibleChanged: if (visible) forceActiveFocus()
                    onAccepted: {
                        entry.modelData.connectWithPsk(text);
                        text = "";
                        root.passphraseFor = null;
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: passphrase.text === ""
                        text: "Password"
                        color: Theme.textSecondary
                        font: passphrase.font
                    }
                }
            }
        }
    }
}
