pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

// Runs shell commands for the launcher: in a terminal that stays open until Enter,
// or in the background with a notification if they fail.
// The terminal is $TERMINAL, else the first installed one from Config.terminals.
Singleton {
    id: root

    property string terminal: Quickshell.env("TERMINAL") ?? ""
    readonly property string name: terminal.split("/").pop()

    // How each terminal takes a command to run; others get "-e".
    readonly property var execArgs: ({
        "foot": [], "kitty": [], "wezterm": ["start", "--"], "gnome-terminal": ["--"], "ptyxis": ["--"]
    })

    function run(command, inTerminal) {
        const shell = Quickshell.env("SHELL") || "sh";
        if (inTerminal && terminal !== "") {
            const script = `"$1" -c "$2"; status=$?; printf '\\n\\033[2m[exited with %s, press Enter to close]\\033[0m' "$status"; read -r _`;
            Quickshell.execDetached([terminal, ...(execArgs[name] ?? ["-e"]), "sh", "-c", script, "sh", shell, command]);
        } else {
            Quickshell.execDetached(["sh", "-c", `"$1" -c "$2" || { status=$?; command -v notify-send >/dev/null && notify-send -a Umbra "Command failed" "$2 exited with $status"; }`, "sh", shell, command]);
        }
    }

    Process {
        running: root.terminal === ""
        command: ["sh", "-c", 'for t in "$@"; do command -v "$t" >/dev/null && { echo "$t"; exit; }; done', "sh", ...Array.from(Config.terminals)]
        stdout: StdioCollector {
            onStreamFinished: root.terminal = text.trim()
        }
    }
}
