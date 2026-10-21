import QtQuick
import QtQuick.Shapes
import qs.config
import "icons.js" as Icons

// Vector line icon from icons.js, tinted with the theme.
Item {
    id: root

    property string name
    property color color: Theme.text
    property real size: 16
    property real strokeWidth: 2
    readonly property bool filled: Icons.filled.includes(name)

    implicitWidth: size
    implicitHeight: size

    Shape {
        anchors.centerIn: parent
        width: 24
        height: 24
        scale: root.size / 24
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            strokeColor: root.color
            strokeWidth: root.strokeWidth
            fillColor: root.filled ? root.color : "transparent"
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin

            PathSvg { path: Icons.paths[root.name] ?? "" }
        }
    }
}
