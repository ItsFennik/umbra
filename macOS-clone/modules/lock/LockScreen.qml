import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pam
import Quickshell.Wayland
import qs.config
import qs.services

// Lock screen through ext-session-lock, drawn by Orbital (the clockwork skin from Ryoku/qylock)
// on every screen; the password is checked by PAM's "login" service. Also locks on logind's Lock
// signal, so `loginctl lock-session` and idle daemons work too.
//   qs -p <umbra dir> ipc call lock lock
Scope {
    id: root

    IpcHandler {
        target: "lock"

        function lock(): void { Session.locked = true; }
        function isLocked(): bool { return Session.locked; }
    }

    // Follows this session's logind object for Lock signals.
    Process {
        running: true
        command: ["sh", "-c", `
            path=$(busctl --system call org.freedesktop.login1 /org/freedesktop/login1 \\
                org.freedesktop.login1.Manager GetSession s "\${XDG_SESSION_ID:-auto}" | cut -d'"' -f2)
            exec gdbus monitor --system --dest org.freedesktop.login1 --object-path "$path"`]
        stdout: SplitParser {
            onRead: line => {
                if (line.includes("org.freedesktop.login1.Session.Lock "))
                    Session.locked = true;
            }
        }
    }

    // Each screen's Orbital; told how PAM answered.
    signal succeeded()
    signal failed()
    signal informed(string message)

    PamContext {
        id: pam

        property string password: ""

        onPamMessage: {
            if (responseRequired)
                respond(password);
            else if (message !== "")
                root.informed(message);
        }
        onCompleted: result => {
            password = "";
            if (result === PamResult.Success) {
                root.succeeded();
                // Let the closing reveal play before the lock goes.
                unlockDelay.interval = Theme.animations ? 720 : 0;
                unlockDelay.restart();
            } else {
                root.failed();
            }
        }
    }

    Timer {
        id: unlockDelay
        onTriggered: Session.locked = false
    }

    function unlock(password) {
        if (pam.active || unlockDelay.running || password === "")
            return;
        pam.password = password;
        pam.start();
    }

    WlSessionLock {
        id: lock
        locked: Session.locked
        onLockedChanged: if (locked) Panels.close()

        WlSessionLockSurface {
            color: "black"

            Orbital {
                id: orbital
                anchors.fill: parent
                onSubmit: password => root.unlock(password)

                Connections {
                    target: root
                    function onSucceeded() { orbital.succeed(); }
                    function onFailed() { orbital.fail(); }
                    function onInformed(message) { orbital.inform(message); }
                }
            }
        }
    }
}
