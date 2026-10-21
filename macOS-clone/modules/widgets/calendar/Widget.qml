import QtQuick
import Quickshell
import qs.components
import qs.config
import qs.modules.widgets

// Month grid. The arrows and the scroll wheel change month; clicking the title returns to today.
WidgetBase {
    id: root

    property int monthOffset: 0

    // JS day numbers: 0 is Sunday. Qt's Locale uses 7 for Sunday.
    readonly property int firstDay: options.firstDay === "monday" ? 1 : options.firstDay === "sunday" ? 0 : Qt.locale().firstDayOfWeek % 7
    readonly property date today: clock.date
    readonly property date shown: new Date(today.getFullYear(), today.getMonth() + monthOffset, 1)
    readonly property var cells: {
        const start = new Date(shown);
        start.setDate(1 - (shown.getDay() - firstDay + 7) % 7);
        const result = [];
        for (let i = 0; i < 42; i++) {
            const d = new Date(start.getFullYear(), start.getMonth(), start.getDate() + i);
            result.push({
                day: d.getDate(),
                inMonth: d.getMonth() === shown.getMonth(),
                today: d.toDateString() === today.toDateString(),
                weekend: d.getDay() === 0 || d.getDay() === 6
            });
        }
        return result;
    }
    readonly property real cellWidth: (width - 28) / 7
    readonly property real cellHeight: (height - header.height - weekdays.height - 32) / 6

    SystemClock {
        id: clock
        precision: SystemClock.Hours
    }

    WidgetCard {}

    WheelHandler {
        onWheel: event => root.monthOffset += event.angleDelta.y > 0 ? -1 : 1
    }

    Item {
        id: header
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 14 }
        height: 26

        MouseArea {
            anchors { left: parent.left; verticalCenter: parent.verticalCenter }
            width: title.implicitWidth
            height: parent.height
            cursorShape: root.monthOffset !== 0 ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: root.monthOffset = 0

            Text {
                id: title
                anchors.verticalCenter: parent.verticalCenter
                text: Qt.locale().standaloneMonthName(root.shown.getMonth()) + " " + root.shown.getFullYear()
                color: Theme.text
                font { family: Theme.font; pixelSize: Theme.px(15); weight: Theme.weight(Font.DemiBold) }
            }
        }

        Row {
            anchors { right: parent.right; verticalCenter: parent.verticalCenter }
            spacing: 2

            Repeater {
                model: [{ icon: "chevron-left", step: -1 }, { icon: "chevron-right", step: 1 }]

                delegate: MouseArea {
                    id: arrow
                    required property var modelData
                    width: 24
                    height: 24
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.monthOffset += modelData.step

                    Rectangle {
                        anchors.fill: parent
                        radius: 12
                        color: arrow.containsMouse ? Theme.hover : "transparent"
                    }

                    Icon {
                        anchors.centerIn: parent
                        name: arrow.modelData.icon
                        size: 14
                        color: Theme.textSecondary
                    }
                }
            }
        }
    }

    Row {
        id: weekdays
        anchors { left: parent.left; leftMargin: 14; top: header.bottom; topMargin: 8 }
        height: 18

        Repeater {
            model: 7

            delegate: Text {
                required property int index
                width: root.cellWidth
                horizontalAlignment: Text.AlignHCenter
                // Locale.dayName takes 0 for Sunday, like JS.
                text: Qt.locale().dayName((root.firstDay + index) % 7, Locale.NarrowFormat)
                color: Theme.textSecondary
                font { family: Theme.font; pixelSize: Theme.px(11); weight: Theme.weight(Font.DemiBold) }
            }
        }
    }

    Grid {
        anchors { left: parent.left; leftMargin: 14; top: weekdays.bottom; topMargin: 4 }
        columns: 7

        Repeater {
            model: root.cells

            delegate: Item {
                id: cell
                required property var modelData
                width: root.cellWidth
                height: root.cellHeight

                Rectangle {
                    anchors.centerIn: parent
                    width: Math.min(parent.width, parent.height) - 2
                    height: width
                    radius: width / 2
                    visible: cell.modelData.today && cell.modelData.inMonth
                    color: Theme.accent
                }

                Text {
                    anchors.centerIn: parent
                    visible: cell.modelData.inMonth || (root.options.showOtherMonths ?? true)
                    text: cell.modelData.day
                    color: cell.modelData.today && cell.modelData.inMonth ? Theme.onAccent : cell.modelData.inMonth ? Theme.text : Theme.textSecondary
                    opacity: cell.modelData.inMonth ? (cell.modelData.weekend && root.options.dimWeekends && !cell.modelData.today ? 0.55 : 1) : 0.45
                    font { family: Theme.font; pixelSize: Theme.px(12); weight: Theme.weight(cell.modelData.today ? Font.DemiBold : Font.Normal); features: { "tnum": 1 } }
                }
            }
        }
    }
}
