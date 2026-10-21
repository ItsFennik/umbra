pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Notifications

// freedesktop notification server. Another running server (e.g. a different shell)
// owns the bus name first; Umbra then simply receives nothing.
Singleton {
    id: root

    property bool doNotDisturb: false

    // Newest first.
    readonly property var history: server.trackedNotifications.values.slice().reverse()

    // Arrival times by notification id; the protocol carries no timestamp.
    property var receivedAt: ({})

    // Notifications currently shown as banners.
    property list<QtObject> banners: []

    function hideBanner(notification) {
        banners = banners.filter(n => n !== notification);
    }

    function clearAll() {
        for (const n of server.trackedNotifications.values.slice())
            n.dismiss();
    }

    function age(notification, now) {
        const at = notification ? receivedAt[notification.id] : null;
        if (!at)
            return "";
        const minutes = Math.floor((now - at) / 60000);
        if (minutes < 1)
            return "now";
        if (minutes < 60)
            return minutes + "m ago";
        return Qt.formatTime(at, "HH:mm");
    }

    // Runs the default action when there is one.
    function activate(notification) {
        const action = notification.actions.find(a => a.identifier === "default");
        if (action)
            action.invoke();
        else
            notification.dismiss();
    }

    NotificationServer {
        id: server

        keepOnReload: false
        actionsSupported: true
        bodySupported: true
        bodyMarkupSupported: true
        imageSupported: true
        persistenceSupported: true

        onNotification: notification => {
            notification.tracked = true;
            root.receivedAt[notification.id] = new Date();
            notification.closed.connect(() => root.hideBanner(notification));
            if (!root.doNotDisturb || notification.urgency === NotificationUrgency.Critical)
                root.banners = [notification, ...root.banners];
        }
    }
}
