import QtQuick
import qs.config

// Filled line graph of `values`, scaled to `maximum` (or to the largest value when 0).
Canvas {
    id: root

    property var values: []
    property real maximum: 0
    property color color: Theme.accent

    onValuesChanged: requestPaint()
    onColorChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()

    onPaint: {
        const ctx = getContext("2d");
        ctx.reset();
        if (values.length < 2)
            return;
        const top = maximum > 0 ? maximum : Math.max(...values, 1e-9);
        const step = width / (values.length - 1);
        const yOf = v => height - Math.max(0, Math.min(1, v / top)) * (height - 2) - 1;
        ctx.beginPath();
        ctx.moveTo(0, yOf(values[0]));
        for (let i = 1; i < values.length; i++)
            ctx.lineTo(i * step, yOf(values[i]));
        ctx.strokeStyle = color;
        ctx.lineWidth = 1.5;
        ctx.lineJoin = "round";
        ctx.stroke();
        ctx.lineTo(width, height);
        ctx.lineTo(0, height);
        ctx.closePath();
        ctx.fillStyle = Qt.alpha(color, 0.18);
        ctx.fill();
    }
}
