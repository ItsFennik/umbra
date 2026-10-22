import QtQuick

// One of the 60 ticks on an Orbital dial; every fifth carries its number. The tick at the dial's
// rightmost point (where it meets the hour) is lit up.
Item {
    id: root

    required property int index
    property real angle: 0
    property real radius: 0
    property real cx: 0
    property real cy: 0
    property real s: 1
    property bool isLight: false
    property string fontFamily: ""
    property real tickWidth: 1
    property real tickHeight: 10
    property real labelInset: 30
    property real labelSize: 16

    readonly property bool isMajor: index % 5 === 0
    readonly property real base: index * 6
    readonly property real relAngle: {
        let a = (base + angle) % 360;
        if (a > 180) a -= 360;
        if (a < -180) a += 360;
        return a;
    }
    readonly property real spotlight: Math.max(0, 1 - Math.abs(relAngle) / 4)
    readonly property real disp: (base + angle) * Math.PI / 180
    readonly property real tx: cx + radius * Math.cos(disp)
    readonly property real ty: cy + radius * Math.sin(disp)

    z: 10
    visible: tx > -600 * s && tx < 1800 * s

    Rectangle {
        x: root.tx - width / 2
        y: root.ty - height / 2
        width: root.tickWidth * root.s
        height: root.tickHeight * root.s
        rotation: root.disp * 180 / Math.PI + 90
        color: root.isLight ? Qt.rgba(0, 0, 0, root.spotlight > 0 ? 1 : (root.isMajor ? 0.8 : 0.6))
                            : Qt.rgba(1, 1, 1, root.spotlight > 0 ? 1 : (root.isMajor ? 0.3 : 0.15))
    }

    Text {
        readonly property real nRad: root.radius - root.labelInset * root.s

        visible: root.isMajor
        x: root.cx + nRad * Math.cos(root.disp) - width / 2
        y: root.cy + nRad * Math.sin(root.disp) - height / 2
        rotation: root.disp * 180 / Math.PI
        text: String(root.index).padStart(2, "0")
        color: root.isLight ? Qt.rgba(0, 0, 0, root.spotlight > 0 ? 0.6 + 0.4 * root.spotlight : 0.6)
                            : Qt.rgba(1, 1, 1, root.spotlight > 0 ? 0.4 + 0.6 * root.spotlight : 0.25)
        font { family: root.fontFamily; pixelSize: root.labelSize * root.s; weight: root.spotlight > 0.5 ? Font.Bold : Font.Normal }
    }
}
