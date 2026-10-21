import QtQuick
import qs.config

// Umbra mark: a crescent cut from a disc.
Canvas {
    implicitWidth: 15
    implicitHeight: 15

    property color tint: Theme.text
    onTintChanged: requestPaint()

    onPaint: {
        const ctx = getContext("2d");
        const r = width / 2;
        ctx.reset();
        ctx.fillStyle = tint;
        ctx.beginPath();
        ctx.arc(r, r, r, 0, 2 * Math.PI);
        ctx.fill();
        ctx.globalCompositeOperation = "destination-out";
        ctx.beginPath();
        ctx.arc(r + r * 0.55, r - r * 0.35, r * 0.85, 0, 2 * Math.PI);
        ctx.fill();
    }
}
