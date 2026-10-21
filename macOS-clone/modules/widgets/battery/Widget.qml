import QtQuick
import QtQuick.Shapes
import qs.components
import qs.config
import qs.services
import qs.modules.widgets

// Charge ring with the percentage inside and the charging state below.
WidgetBase {
    id: root

    readonly property real level: Battery.percentage
    readonly property bool low: Battery.available && !Battery.charging && level * 100 <= (options.lowLevel ?? 20)
    readonly property color tint: Battery.charging ? "#30d158" : low ? Theme.destructive : Theme.accent
    readonly property real ring: Math.max(40, Math.min(width - 32, height - (status.visible ? 64 : 36)))

    function duration(seconds) {
        const m = Math.round(seconds / 60);
        return Math.floor(m / 60) + ":" + String(m % 60).padStart(2, "0");
    }

    readonly property string statusText: {
        if (!Battery.available)
            return "No battery";
        if (Battery.full)
            return "Fully Charged";
        if (Battery.charging)
            return Battery.timeToFull > 0 && (options.showTime ?? true) ? duration(Battery.timeToFull) + " until full" : "Charging";
        return Battery.timeToEmpty > 0 && (options.showTime ?? true) ? duration(Battery.timeToEmpty) + " remaining" : "On Battery";
    }

    WidgetCard {}

    Shape {
        id: gauge
        anchors { horizontalCenter: parent.horizontalCenter; top: parent.top; topMargin: 16 }
        width: root.ring
        height: root.ring
        visible: Battery.available
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            strokeColor: Theme.sliderTrack
            strokeWidth: Math.max(6, root.ring * 0.08)
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            PathAngleArc {
                centerX: gauge.width / 2; centerY: gauge.height / 2
                radiusX: gauge.width / 2 - gauge.width * 0.06; radiusY: radiusX
                startAngle: -90; sweepAngle: 360
            }
        }

        ShapePath {
            strokeColor: root.tint
            strokeWidth: Math.max(6, root.ring * 0.08)
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            PathAngleArc {
                centerX: gauge.width / 2; centerY: gauge.height / 2
                radiusX: gauge.width / 2 - gauge.width * 0.06; radiusY: radiusX
                startAngle: -90; sweepAngle: 360 * Math.max(0.01, root.level)
                Behavior on sweepAngle { NumberAnimation { duration: Theme.durationMedium; easing.type: Theme.easing } }
            }
        }

        Column {
            anchors.centerIn: parent

            Icon {
                anchors.horizontalCenter: parent.horizontalCenter
                visible: Battery.charging
                name: "bolt"
                size: Math.max(10, root.ring * 0.13)
                strokeWidth: 1
                color: root.tint
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Math.round(root.level * 100) + "%"
                color: Theme.text
                font { family: Theme.font; pixelSize: Math.max(Theme.px(14), root.ring * 0.24); weight: Theme.weight(Font.DemiBold); features: { "tnum": 1 } }
            }
        }
    }

    Icon {
        anchors.centerIn: gauge
        visible: !Battery.available
        name: "battery"
        size: 36
        color: Theme.textSecondary
    }

    Text {
        id: status
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom; bottomMargin: 16; margins: 12 }
        horizontalAlignment: Text.AlignHCenter
        elide: Text.ElideRight
        text: root.statusText
        color: root.low ? Theme.destructive : Theme.textSecondary
        font { family: Theme.font; pixelSize: Theme.px(12); weight: Theme.weight(Font.Medium); features: { "tnum": 1 } }
    }
}
