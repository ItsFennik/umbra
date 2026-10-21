import QtQuick
import qs.components
import qs.config
import qs.services
import qs.modules.widgets

// Download and upload throughput across physical interfaces, from /proc/net/dev.
WidgetBase {
    id: root

    readonly property string key: "network-" + Math.random().toString(36).slice(2)
    readonly property int interval: Number(options.interval ?? 2000)
    readonly property bool bits: options.units === "bits"
    readonly property string connection: NetworkService.activeNetwork?.name ?? (NetworkService.wiredConnected ? "Ethernet" : "Offline")

    onIntervalChanged: SystemStats.acquire(key, interval)
    Component.onCompleted: SystemStats.acquire(key, interval)
    Component.onDestruction: SystemStats.release(key)

    WidgetCard {}

    Row {
        id: header
        anchors { left: parent.left; top: parent.top; margins: 14 }
        spacing: 6

        Icon {
            anchors.verticalCenter: parent.verticalCenter
            name: NetworkService.available ? NetworkService.icon : "wifi-off"
            size: 13
            color: Theme.textSecondary
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            width: root.width - 50
            elide: Text.ElideRight
            text: SystemStats.available ? root.connection : "Network statistics unavailable"
            color: Theme.textSecondary
            font { family: Theme.font; pixelSize: Theme.px(11); weight: Theme.weight(Font.Medium) }
        }
    }

    Row {
        id: rates
        anchors { left: parent.left; right: parent.right; top: header.bottom; margins: 14; topMargin: 8 }

        Repeater {
            model: [
                { icon: "arrow-down", rate: SystemStats.rxRate, color: Theme.accent },
                { icon: "arrow-up", rate: SystemStats.txRate, color: Theme.textSecondary }
            ]

            delegate: Row {
                required property var modelData
                width: rates.width / 2
                spacing: 6

                Icon {
                    anchors.verticalCenter: parent.verticalCenter
                    name: modelData.icon
                    size: 14
                    color: modelData.color
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: SystemStats.formatBytes(modelData.rate, true, root.bits)
                    color: Theme.text
                    font { family: Theme.font; pixelSize: Theme.px(16); weight: Theme.weight(Font.DemiBold); features: { "tnum": 1 } }
                }
            }
        }
    }

    // Both directions share one scale so they compare honestly.
    Item {
        visible: root.options.showGraph ?? true
        anchors { left: parent.left; right: parent.right; top: rates.bottom; bottom: parent.bottom; margins: 14; topMargin: 10 }

        readonly property real peak: Math.max(1024, ...SystemStats.rxHistory, ...SystemStats.txHistory)

        Sparkline {
            anchors.fill: parent
            values: SystemStats.txHistory
            maximum: parent.peak
            color: Theme.textSecondary
        }

        Sparkline {
            anchors.fill: parent
            values: SystemStats.rxHistory
            maximum: parent.peak
            color: Theme.accent
        }
    }
}
