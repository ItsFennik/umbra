import QtQuick
import qs.services

// Shared interface for desktop widgets. A widget type is a folder modules/widgets/<id>/ with a
// manifest.json (see services/Widgets.qml) and a Widget.qml whose root is a WidgetBase.
// WidgetFrame sizes it and fills these in; read settings from `options`.
Item {
    property string widgetId
    // The manifest's setting defaults merged with this widget's saved values.
    property var options: ({})
    property var screen: null

    function setOption(key, value) {
        Widgets.configure(widgetId, key, value);
    }
}
