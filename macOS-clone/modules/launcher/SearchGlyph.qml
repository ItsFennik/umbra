import QtQuick
import qs.config

// Magnifying glass drawn in code so it matches the theme without an icon font.
Canvas {
    implicitWidth: 20
    implicitHeight: 20

    property color tint: Theme.textSecondary
    onTintChanged: requestPaint()

    onPaint: {
        const ctx = getContext("2d");
        ctx.reset();
        ctx.strokeStyle = tint;
        ctx.lineWidth = 2;
        ctx.lineCap = "round";
        ctx.beginPath();
        ctx.arc(8.5, 8.5, 6, 0, 2 * Math.PI);
        ctx.stroke();
        ctx.beginPath();
        ctx.moveTo(13, 13);
        ctx.lineTo(18, 18);
        ctx.stroke();
    }
}
