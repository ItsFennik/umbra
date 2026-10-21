import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import qs.components
import qs.config
import qs.services
import "calc.js" as Calc
import "emoji.js" as Emoji

// Spotlight-style search. Plain text finds apps, and arithmetic shows its result; prefixes switch mode:
//   e> emoji      c> clipboard history (cliphist)      > shell command      = calculator
// With an empty field it lists recent searches. Toggle from a compositor keybind with:
//   qs -p <umbra dir> ipc call launcher toggle        (also: emoji, clipboard, command, search <text>)
Scope {
    id: launcher

    // Text to open with, set by the IPC calls below.
    property string initialText: ""
    signal requested(string text)

    function openWith(text) {
        initialText = text;
        if (Panels.current === "launcher")
            requested(text);
        else
            Panels.open("launcher");
    }

    IpcHandler {
        target: "launcher"

        function toggle(): void { launcher.initialText = ""; Panels.toggle("launcher"); }
        function open(): void { launcher.openWith(""); }
        function close(): void { Panels.close(); }
        function emoji(): void { launcher.openWith("e> "); }
        function clipboard(): void { launcher.openWith("c> "); }
        function command(): void { launcher.openWith("> "); }
        function search(text: string): void { launcher.openWith(text); }
    }

    LazyLoader {
        active: Panels.current === "launcher"

        PanelWindow {
            id: window

            screen: Compositor.focusedScreen ?? Quickshell.screens[0]
            anchors { top: true; bottom: true; left: true; right: true }
            exclusionMode: ExclusionMode.Ignore
            color: "transparent"

            WlrLayershell.namespace: "umbra-launcher"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
            BackgroundEffect.blurRegion: Region { item: Theme.blur ? panel : null }

            readonly property var modes: [
                { prefix: "e>", id: "emoji", text: "Emoji", placeholder: "Search emoji" },
                { prefix: "c>", id: "clipboard", text: "Clipboard", placeholder: "Search clipboard history" },
                { prefix: ">", id: "command", text: "Command", placeholder: "Run a command" },
                { prefix: "=", id: "calc", text: "Calculator", placeholder: "Type an expression" }
            ]
            // Typing a prefix at the start enters its mode; the prefix becomes the chip.
            property var mode: null
            readonly property string query: field.text.trim()
            readonly property string fullText: (mode ? mode.prefix + " " : "") + field.text

            property var emojiList: []
            property var results: []
            property int selected: 0
            readonly property var current: results[selected] ?? null
            readonly property int visibleRows: 8
            readonly property int rowHeight: 40

            onResultsChanged: selected = 0
            onModeChanged: {
                refresh.restart();
                if (mode?.id === "clipboard")
                    Clipboard.refresh();
                if (mode?.id === "emoji" && emojiList.length === 0)
                    emojiList = Emoji.data.split("\n").map(line => {
                        const [glyph, name, group, subgroup] = line.split("\t");
                        return { glyph: glyph, name: name, tags: Emoji.groups[group] + " " + subgroup };
                    });
            }

            // Recomputed on the next frame so typing never waits on a search.
            Timer {
                id: refresh
                interval: 0
                onTriggered: window.results = window.search()
            }
            Connections {
                target: field
                function onTextChanged() {
                    const m = window.mode ? null : window.modes.find(m => field.text.startsWith(m.prefix));
                    if (m) {
                        window.mode = m;
                        field.text = field.text.slice(m.prefix.length).replace(/^\s+/, "");
                    }
                    refresh.restart();
                }
            }
            Connections {
                target: Clipboard
                function onEntriesChanged() { if (window.mode?.id === "clipboard") refresh.restart(); }
                function onAvailableChanged() { refresh.restart(); }
            }
            Connections {
                target: Terminal
                function onTerminalChanged() { refresh.restart(); }
            }
            Connections {
                target: launcher
                function onRequested(text) {
                    window.mode = null;
                    field.text = text;
                    field.cursorPosition = field.text.length;
                }
            }
            Component.onCompleted: {
                field.text = launcher.initialText;
                launcher.initialText = "";
                refresh.restart();
            }

            function search() {
                switch (mode?.id) {
                case "emoji": return emojiResults();
                case "clipboard": return clipboardResults();
                case "command": return commandResults();
                case "calc": return calcResults(true);
                }
                if (query === "")
                    return recentResults();
                const results = calcResults(false);
                const counts = LauncherHistory.apps;
                for (const entry of Apps.search(query, 8, e => Math.min(15, (counts[e.id] ?? 0) * 3)))
                    results.push({
                        icon: Apps.iconFor(entry, entry.id),
                        title: entry.name,
                        subtitle: entry.genericName || entry.comment,
                        action: "Open",
                        record: true,
                        run: () => { LauncherHistory.recordApp(entry.id); entry.execute(); }
                    });
                if (results.length === 0)
                    results.push(runItem(query));
                return results;
            }

            function recentResults() {
                return LauncherHistory.queries.slice(0, 8).map(q => ({
                    symbol: "history",
                    title: q,
                    subtitle: "Recent search",
                    action: "Search",
                    keepOpen: true,
                    run: () => { field.text = q; field.cursorPosition = field.text.length; },
                    remove: () => LauncherHistory.removeQuery(q)
                }));
            }

            function calcResults(forced) {
                if (!forced && !Calc.looksLikeMath(query))
                    return [];
                if (query === "")
                    return [{ symbol: "calculator", title: "Type an expression", subtitle: "+ − × ÷ % ^, sqrt, sin, log, pi…", enabled: false }];
                try {
                    const value = Calc.format(Calc.evaluate(query));
                    return [{
                        symbol: "calculator",
                        title: "= " + value,
                        subtitle: query,
                        action: Clipboard.canCopy ? "Copy" : "",
                        record: true,
                        enabled: Clipboard.canCopy,
                        run: () => Clipboard.copyText(value)
                    }];
                } catch (e) {
                    return forced ? [{ symbol: "calculator", title: e.message, subtitle: query, enabled: false }] : [];
                }
            }

            function emojiResults() {
                const q = query.toLowerCase();
                let list;
                if (q === "") {
                    const recent = LauncherHistory.emoji.map(g => emojiList.find(e => e.glyph === g)).filter(e => e);
                    list = recent.concat(emojiList.filter(e => !recent.includes(e))).slice(0, 60);
                } else {
                    const score = e => {
                        const name = e.name.toLowerCase();
                        if (name === q) return 4;
                        if (name.startsWith(q)) return 3;
                        if (name.split(/[\s:-]+/).some(w => w.startsWith(q))) return 2;
                        if (name.includes(q)) return 1;
                        return e.tags.includes(q) ? 0.5 : 0;
                    };
                    list = emojiList.map(e => ({ e: e, s: score(e) })).filter(r => r.s > 0)
                        .sort((a, b) => b.s - a.s).slice(0, 60).map(r => r.e);
                }
                return list.map(e => ({
                    glyph: e.glyph,
                    title: e.name.charAt(0).toUpperCase() + e.name.slice(1),
                    subtitle: e.tags,
                    action: "Copy",
                    record: q !== "",
                    enabled: Clipboard.canCopy,
                    run: () => { LauncherHistory.recordEmoji(e.glyph); Clipboard.copyText(e.glyph); }
                }));
            }

            function clipboardResults() {
                if (!Clipboard.available)
                    return [{ symbol: "clipboard", title: "Clipboard history needs cliphist and wl-clipboard", subtitle: "and wl-paste --watch cliphist store", enabled: false }];
                const q = query.toLowerCase();
                const list = Clipboard.entries.filter(e => q === "" || e.text.toLowerCase().includes(q)).map(e => ({
                    symbol: e.binary ? "image" : "clipboard",
                    title: e.text.replace(/\s+/g, " ").trim() || " ",
                    subtitle: "",
                    action: "Copy",
                    run: () => Clipboard.copyEntry(e),
                    remove: () => Clipboard.remove(e)
                }));
                if (list.length === 0)
                    list.push({ symbol: "clipboard", title: Clipboard.loading ? "Loading…" : q === "" ? "Clipboard history is empty" : "No matches", subtitle: "", enabled: false });
                return list;
            }

            function runItem(command) {
                return {
                    symbol: "terminal",
                    title: "Run “" + command + "”",
                    subtitle: Terminal.terminal !== "" ? "in " + Terminal.name : "in the background",
                    action: "Run",
                    altAction: "Run in background",
                    run: () => { LauncherHistory.recordCommand(command); Terminal.run(command, true); },
                    alt: () => { LauncherHistory.recordCommand(command); Terminal.run(command, false); }
                };
            }

            function commandResults() {
                const q = query;
                const results = q !== "" ? [runItem(q)] : [];
                for (const c of LauncherHistory.commands) {
                    if (c === q || (q !== "" && !c.includes(q)))
                        continue;
                    results.push(Object.assign(runItem(c), {
                        symbol: "history",
                        title: c,
                        remove: () => LauncherHistory.removeCommand(c)
                    }));
                }
                if (results.length === 0)
                    results.push({ symbol: "terminal", title: "Type a command", subtitle: "Enter runs it in " + (Terminal.name || "a terminal") + ", Shift+Enter in the background", enabled: false });
                return results;
            }

            function activate(item, alternate) {
                if (!item || item.enabled === false)
                    return;
                const action = alternate ? item.alt : item.run;
                if (!action)
                    return;
                if (item.record || mode)
                    LauncherHistory.recordQuery(fullText);
                try {
                    action();
                } catch (e) {
                    console.warn("Umbra: launcher action failed:", e);
                }
                if (!item.keepOpen)
                    Panels.close();
            }

            function move(delta, wrap) {
                const n = results.length;
                if (n === 0)
                    return;
                selected = wrap ? (selected + delta + n) % n : Math.max(0, Math.min(n - 1, selected + delta));
            }

            // Clicking anywhere outside the panel dismisses it.
            MouseArea {
                anchors.fill: parent
                onClicked: Panels.close()
            }

            Rectangle {
                id: panel

                x: (parent.width - width) / 2
                y: Math.round(parent.height * 0.22)
                width: 640
                height: column.implicitHeight
                radius: 14
                color: Theme.popupBackground
                border { width: 1; color: Theme.dockBorder }
                clip: true

                opacity: 0
                scale: 0.98
                Component.onCompleted: { opacity = 1; scale = 1; }
                Behavior on opacity { NumberAnimation { duration: Theme.durationShort } }
                Behavior on scale { NumberAnimation { duration: Theme.durationMedium; easing.type: Theme.easing } }
                Behavior on height { NumberAnimation { duration: Theme.durationShort; easing.type: Theme.easing } }

                // Swallow clicks so they do not reach the dismiss area.
                MouseArea { anchors.fill: parent }

                Column {
                    id: column
                    width: parent.width

                    Item {
                        width: parent.width
                        height: 52

                        SearchGlyph {
                            id: glyph
                            anchors { left: parent.left; leftMargin: 18; verticalCenter: parent.verticalCenter }
                        }

                        // The active mode as a chip before the query.
                        Rectangle {
                            id: chip
                            anchors { left: glyph.right; leftMargin: 10; verticalCenter: parent.verticalCenter }
                            visible: window.mode !== null
                            width: visible ? chipLabel.implicitWidth + 14 : 0
                            height: 22
                            radius: 6
                            color: Theme.accent

                            Text {
                                id: chipLabel
                                anchors.centerIn: parent
                                text: window.mode?.text ?? ""
                                color: Theme.onAccent
                                font { family: Theme.font; pixelSize: Theme.px(12); weight: Theme.weight(Font.DemiBold) }
                            }
                        }

                        TextInput {
                            id: field
                            anchors { left: chip.visible ? chip.right : glyph.right; leftMargin: chip.visible ? 8 : 12; right: parent.right; rightMargin: 18; verticalCenter: parent.verticalCenter }
                            focus: true
                            clip: true
                            color: Theme.text
                            selectionColor: Theme.accent
                            selectedTextColor: Theme.onAccent
                            font { family: Theme.font; weight: Theme.fontWeight; pixelSize: Theme.px(20) }

                            Keys.onPressed: event => {
                                const ctrl = event.modifiers & Qt.ControlModifier;
                                const shift = event.modifiers & Qt.ShiftModifier;
                                if (event.key === Qt.Key_Escape) {
                                    if (field.text !== "")
                                        field.text = "";
                                    else if (window.mode)
                                        window.mode = null;
                                    else
                                        Panels.close();
                                } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                    window.activate(window.current, shift);
                                } else if (event.key === Qt.Key_Up || (ctrl && event.key === Qt.Key_P)) {
                                    window.move(-1, false);
                                } else if (event.key === Qt.Key_Down || (ctrl && event.key === Qt.Key_N)) {
                                    window.move(1, false);
                                } else if (event.key === Qt.Key_Tab) {
                                    window.move(1, true);
                                } else if (event.key === Qt.Key_Backtab) {
                                    window.move(-1, true);
                                } else if (event.key === Qt.Key_PageUp) {
                                    window.move(-window.visibleRows, false);
                                } else if (event.key === Qt.Key_PageDown) {
                                    window.move(window.visibleRows, false);
                                } else if (ctrl && event.key >= Qt.Key_1 && event.key <= Qt.Key_9) {
                                    window.activate(window.results[list.indexAt(0, list.contentY + 1) + event.key - Qt.Key_1], shift);
                                } else if (shift && event.key === Qt.Key_Delete && window.current?.remove) {
                                    window.current.remove();
                                    refresh.restart();
                                } else if (event.key === Qt.Key_Backspace && window.mode && field.cursorPosition === 0 && field.selectedText === "") {
                                    // Backspace at the start of a mode leaves it.
                                    window.mode = null;
                                } else {
                                    return;
                                }
                                event.accepted = true;
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                visible: field.text === ""
                                text: window.mode?.placeholder ?? "Search apps, calculate, or type e>, c>, >"
                                color: Theme.textSecondary
                                font: field.font
                            }
                        }
                    }

                    Rectangle {
                        visible: window.results.length > 0
                        width: parent.width
                        height: 1
                        color: Theme.hairline
                    }

                    Item {
                        width: parent.width
                        height: window.results.length > 0 ? list.height + 12 : 0

                        ListView {
                            id: list
                            y: 6
                            width: parent.width
                            height: Math.min(window.results.length, window.visibleRows) * window.rowHeight
                            clip: true
                            model: window.results
                            currentIndex: window.selected
                            highlightFollowsCurrentItem: false
                            boundsBehavior: Flickable.StopAtBounds
                            onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Contain)

                            delegate: MouseArea {
                                id: row
                                required property var modelData
                                required property int index

                                readonly property bool current: index === window.selected
                                readonly property bool active: modelData.enabled !== false

                                x: 6
                                width: list.width - 12
                                height: window.rowHeight
                                hoverEnabled: true
                                cursorShape: active ? Qt.PointingHandCursor : Qt.ArrowCursor
                                onEntered: window.selected = index
                                onClicked: window.activate(modelData, false)

                                Rectangle {
                                    anchors.fill: parent
                                    radius: 8
                                    color: row.current && row.active ? Theme.accent : row.current ? Theme.hover : "transparent"
                                }

                                Item {
                                    id: rowIcon
                                    anchors { left: parent.left; leftMargin: 10; verticalCenter: parent.verticalCenter }
                                    width: 26
                                    height: 26

                                    IconImage {
                                        anchors.fill: parent
                                        visible: row.modelData.icon !== undefined
                                        source: row.modelData.icon ?? ""
                                        asynchronous: true
                                        mipmap: true
                                    }

                                    Text {
                                        anchors.centerIn: parent
                                        visible: row.modelData.glyph !== undefined
                                        text: row.modelData.glyph ?? ""
                                        font { family: Theme.emojiFont || Theme.font; pixelSize: 21 }
                                    }

                                    Icon {
                                        anchors.centerIn: parent
                                        visible: row.modelData.symbol !== undefined
                                        name: row.modelData.symbol ?? ""
                                        size: 17
                                        color: row.current && row.active ? Theme.onAccent : Theme.textSecondary
                                    }
                                }

                                Text {
                                    id: rowName
                                    anchors { left: rowIcon.right; leftMargin: 12; verticalCenter: parent.verticalCenter }
                                    width: Math.min(implicitWidth, row.width - 120)
                                    elide: Text.ElideRight
                                    text: row.modelData.title
                                    color: row.current && row.active ? Theme.onAccent : row.active ? Theme.text : Theme.textSecondary
                                    font { family: Theme.font; pixelSize: Theme.px(14); weight: Theme.weight(Font.Medium) }
                                }

                                Text {
                                    anchors { left: rowName.right; leftMargin: 10; right: shortcut.left; rightMargin: 10; baseline: rowName.baseline }
                                    text: row.modelData.subtitle ?? ""
                                    elide: Text.ElideRight
                                    color: row.current && row.active ? Qt.alpha(Theme.onAccent, 0.75) : Theme.textSecondary
                                    font { family: Theme.font; weight: Theme.fontWeight; pixelSize: Theme.px(12) }
                                }

                                // Ctrl+number for the first rows in view, the Enter action on the current one.
                                Text {
                                    id: shortcut
                                    readonly property int position: row.index - list.indexAt(0, list.contentY + 1)
                                    anchors { right: parent.right; rightMargin: 12; baseline: rowName.baseline }
                                    text: !row.active ? "" : row.current && row.modelData.action ? row.modelData.action + "  ↵" : position >= 0 && position < 9 ? "⌃" + (position + 1) : ""
                                    color: row.current ? Qt.alpha(Theme.onAccent, 0.75) : Theme.textSecondary
                                    font { family: Theme.font; weight: Theme.fontWeight; pixelSize: Theme.px(11) }
                                }
                            }
                        }
                    }

                    // Shortcut hints: modes on the left, the current row's keys on the right.
                    Rectangle {
                        width: parent.width
                        height: 1
                        color: Theme.hairline
                    }

                    Item {
                        width: parent.width
                        height: 30

                        Row {
                            anchors { left: parent.left; leftMargin: 16; verticalCenter: parent.verticalCenter }
                            spacing: 12

                            Repeater {
                                model: window.mode ? [{ key: "esc", text: field.text === "" ? "Leave " + window.mode.text : "Clear" }, { key: "⌫", text: "Leave", show: field.text === "" }].filter(h => h.show !== false)
                                    : [{ key: "e>", text: "Emoji" }, { key: "c>", text: "Clipboard" }, { key: ">", text: "Command" }, { key: "=", text: "Calculate" }]

                                delegate: FooterHint {}
                            }
                        }

                        Row {
                            anchors { right: parent.right; rightMargin: 16; verticalCenter: parent.verticalCenter }
                            spacing: 12

                            Repeater {
                                model: [
                                    { key: "↑↓", text: "Select", show: window.results.length > 1 },
                                    { key: "⇧↵", text: window.current?.altAction ?? "", show: window.current?.alt !== undefined },
                                    { key: "⇧⌦", text: "Remove", show: window.current?.remove !== undefined }
                                ].filter(h => h.show)

                                delegate: FooterHint {}
                            }
                        }
                    }
                }
            }
        }
    }
}
