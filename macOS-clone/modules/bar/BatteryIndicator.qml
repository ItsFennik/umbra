import QtQuick
import qs.components
import qs.config
import qs.services

Row {
    spacing: 5

    Text {
        anchors.verticalCenter: parent.verticalCenter
        text: Math.round(Battery.percentage * 100) + "%"
        color: Theme.text
        font { family: Theme.font; pixelSize: 12; features: { "tnum": 1 } }
    }

    Item {
        anchors.verticalCenter: parent.verticalCenter
        width: 25
        height: 12

        Rectangle {
            id: body
            width: 22
            height: 12
            radius: 3.5
            color: "transparent"
            border { width: 1; color: Qt.alpha(Theme.text, 0.5) }

            Rectangle {
                x: 2
                y: 2
                height: parent.height - 4
                width: Math.max(1.5, (parent.width - 4) * Battery.percentage)
                radius: 1.5
                color: Battery.charging ? "#30d158" : Battery.percentage <= 0.15 ? Theme.destructive : Theme.text
            }
        }

        Rectangle {
            anchors { left: body.right; leftMargin: 1; verticalCenter: body.verticalCenter }
            width: 1.5
            height: 4
            radius: 1
            color: Qt.alpha(Theme.text, 0.5)
        }

        Icon {
            anchors.centerIn: body
            visible: Battery.charging
            name: "bolt"
            size: 9
            strokeWidth: 1
            color: Theme.text
        }
    }
}
