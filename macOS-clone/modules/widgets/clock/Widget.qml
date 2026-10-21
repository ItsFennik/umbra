import QtQuick
import QtQuick.Effects
import Quickshell
import qs.config
import qs.modules.widgets

// Large frameless clock. White with a soft shadow so it reads on any wallpaper; text fits the frame.
WidgetBase {
    id: root

    readonly property bool twelveHour: options.format === "12"

    SystemClock {
        id: clock
        precision: root.options.showSeconds ? SystemClock.Seconds : SystemClock.Minutes
    }

    Item {
        id: content
        anchors { fill: parent; margins: 6 }

        Text {
            id: date
            visible: root.options.showDate
            anchors { left: parent.left; right: parent.right; top: parent.top }
            height: visible ? parent.height * 0.2 : 0
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignBottom
            fontSizeMode: Text.Fit
            minimumPixelSize: 8
            text: Qt.formatDateTime(clock.date, "dddd, MMMM d")
            color: Qt.rgba(1, 1, 1, 0.85)
            font { family: Theme.font; pixelSize: 400; weight: Theme.weight(Font.DemiBold) }
        }

        Text {
            anchors { left: parent.left; right: parent.right; top: date.bottom; bottom: parent.bottom }
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            fontSizeMode: Text.Fit
            minimumPixelSize: 12
            text: Qt.formatDateTime(clock.date, (root.twelveHour ? "h:mm" : "HH:mm") + (root.options.showSeconds ? ":ss" : "") + (root.twelveHour ? " AP" : ""))
            color: "white"
            font { family: Theme.font; pixelSize: 400; weight: Theme.weight(Font.Light); features: { "tnum": 1 } }
        }

        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: Qt.rgba(0, 0, 0, 0.45)
            shadowBlur: 0.8
            shadowVerticalOffset: 2
        }
    }
}
