import QtQuick
import qs.config
import qs.services
import qs.modules.widgets

// CPU load and memory use from /proc, with an optional CPU history graph.
WidgetBase {
    id: root

    readonly property string key: "system-" + Math.random().toString(36).slice(2)
    readonly property int interval: Number(options.interval ?? 2000)

    onIntervalChanged: SystemStats.acquire(key, interval)
    Component.onCompleted: SystemStats.acquire(key, interval)
    Component.onDestruction: SystemStats.release(key)

    component Meter: Column {
        id: meter

        property string label
        property string value
        property real fraction

        width: parent.width
        spacing: 5

        Item {
            width: parent.width
            height: name.implicitHeight

            Text {
                id: name
                text: meter.label
                color: Theme.textSecondary
                font { family: Theme.font; pixelSize: Theme.px(11); weight: Theme.weight(Font.Medium) }
            }

            Text {
                anchors.right: parent.right
                text: meter.value
                color: Theme.text
                font { family: Theme.font; pixelSize: Theme.px(12); weight: Theme.weight(Font.DemiBold); features: { "tnum": 1 } }
            }
        }

        Rectangle {
            width: parent.width
            height: 5
            radius: 2.5
            color: Theme.sliderTrack

            Rectangle {
                width: parent.width * Math.max(0, Math.min(1, meter.fraction))
                height: parent.height
                radius: 2.5
                color: meter.fraction > 0.9 ? Theme.destructive : Theme.accent
                Behavior on width { NumberAnimation { duration: Theme.durationMedium; easing.type: Theme.easing } }
            }
        }
    }

    WidgetCard {}

    Column {
        id: meters
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 14 }
        spacing: 10

        Text {
            visible: !SystemStats.available
            text: "System statistics unavailable"
            color: Theme.textSecondary
            font { family: Theme.font; weight: Theme.fontWeight; pixelSize: Theme.px(12) }
        }

        Meter {
            label: "CPU"
            value: Math.round(SystemStats.cpu * 100) + "%"
            fraction: SystemStats.cpu
        }

        Meter {
            label: "Memory"
            value: SystemStats.formatBytes(SystemStats.memUsed) + " of " + SystemStats.formatBytes(SystemStats.memTotal)
            fraction: SystemStats.memory
        }

        Meter {
            visible: (root.options.showSwap ?? false) && SystemStats.swapTotal > 0
            label: "Swap"
            value: SystemStats.formatBytes(SystemStats.swapUsed) + " of " + SystemStats.formatBytes(SystemStats.swapTotal)
            fraction: SystemStats.swapTotal > 0 ? SystemStats.swapUsed / SystemStats.swapTotal : 0
        }
    }

    Sparkline {
        visible: (root.options.showGraph ?? true) && height > 12
        anchors { left: parent.left; right: parent.right; top: meters.bottom; bottom: parent.bottom; margins: 14; topMargin: 10 }
        values: SystemStats.cpuHistory
        maximum: 1
    }
}
