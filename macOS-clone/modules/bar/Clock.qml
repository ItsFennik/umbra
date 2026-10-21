import QtQuick
import Quickshell
import qs.config

Text {
    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    text: Qt.formatDateTime(clock.date, "ddd d MMM") + "   " + Qt.formatDateTime(clock.date, "HH:mm")
    color: Theme.text
    font { family: Theme.font; pixelSize: Theme.fontSize; weight: Theme.weight(Font.Medium); features: { "tnum": 1 } }
}
