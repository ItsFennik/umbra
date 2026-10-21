import QtQuick
import QtQuick.Effects
import Quickshell
import qs.config

// Large frameless clock. White with a soft shadow so it reads on any wallpaper.
Item {
    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    Column {
        id: content
        anchors.centerIn: parent
        spacing: -6

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatDateTime(clock.date, "dddd, MMMM d")
            color: Qt.rgba(1, 1, 1, 0.85)
            font { family: Theme.font; pixelSize: 18; weight: Font.DemiBold }
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatDateTime(clock.date, "HH:mm")
            color: "white"
            font { family: Theme.font; pixelSize: 96; weight: Font.Light; features: { "tnum": 1 } }
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
