pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

// Sleep, restart, shut down, lock and log out, through systemd-logind.
// Restart, shut down and log out go through the power dialog first, like macOS;
// pending is the action it confirms, or "" to offer them all.
Singleton {
    id: root

    property string pending: ""
    // Shows the lock screen (modules/lock) until PAM accepts the password.
    property bool locked: false

    function request(action, screen) {
        pending = action ?? "";
        Panels.open("power", screen);
    }

    function run(action) {
        Panels.close();
        switch (action) {
        case "sleep": exec(["systemctl", "suspend"]); break;
        case "restart": exec(["systemctl", "reboot"]); break;
        case "shutdown": exec(["systemctl", "poweroff"]); break;
        case "lock": locked = true; break;
        case "logout":
            if (Compositor.adapter?.logout)
                Compositor.adapter.logout();
            else
                exec(["sh", "-c", "loginctl terminate-session \"${XDG_SESSION_ID:-self}\""]);
            break;
        }
    }

    function exec(command) {
        proc.command = command;
        proc.running = true;
    }

    Process {
        id: proc
        onExited: code => {
            if (code !== 0)
                console.warn("Umbra: " + proc.command.join(" ") + " failed with " + code);
        }
    }
}
