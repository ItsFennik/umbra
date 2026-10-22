import QtQuick
import qs.config
import qs.services

// The "Orbital" clockwork lock screen from qylock (github.com/Darkkal44/qylock, GPL-3.0), by way
// of Ryoku: minute and second dials orbit the hour, and unlocking winds them up until they burst.
// Ported off qylock's SDDM shim; LockScreen owns PAM and calls succeed() / fail() / inform().
Rectangle {
    id: root

    // Emitted once the wind-up has played; LockScreen checks the password with PAM.
    signal submit(string password)

    readonly property real s: height / 768
    readonly property bool enableWindup: Theme.animations
    readonly property bool isLight: !Theme.dark

    readonly property color bgColor: isLight ? "#ffffff" : "#000000"
    readonly property color mainText: isLight ? "#000000" : "#ffffff"
    readonly property color dimText: "#666666"
    readonly property color subColor: isLight ? "#666666" : "#555555"
    readonly property color pillColor: isLight ? "#e8e8e8" : "#080808"
    readonly property color pillBorder: isLight ? (isWindup ? "#aaaaaa" : "#cccccc") : (isWindup ? "#444" : "#1a1a1a")
    readonly property color pillInnerLine: isLight ? (isWindup ? "#000000" : "#bbbbbb") : (isWindup ? "#ffffff" : "#222222")
    readonly property color sparkColor: isLight ? "#000000" : "#ffffff"
    readonly property color blastColor: isLight ? "#000000" : "#ffffff"
    readonly property color inputWaitColor: isLight ? "#bbbbbb" : "#333333"

    property bool isWindup: false
    property real uiOpacity: 0
    property string authInfo: ""
    readonly property string inputHint: authInfo !== "" ? authInfo.toUpperCase() : "TYPE PASSWORD"
    readonly property real marginR: 80 * s

    color: bgColor

    // Time; refreshed every frame for the smooth second dial.
    property date now: new Date()
    readonly property real localTimeMS: now.getHours() * 3600000 + now.getMinutes() * 60000 + now.getSeconds() * 1000 + now.getMilliseconds()

    Timer {
        interval: 16
        running: root.visible
        repeat: true
        onTriggered: root.now = new Date()
    }

    // Wind-up animation state.
    property real windupOffset: 0
    readonly property real windupProgress: windupOffset / 150000
    property real boomScale: 1
    property real boomOpacity: 0
    property real jitterX: 0
    property real jitterY: 0
    property real sparkIntensity: 0

    Timer {
        interval: 16
        running: root.isWindup
        repeat: true
        onTriggered: {
            const intensity = root.windupProgress * 32 * root.s;
            root.jitterX = (Math.random() - 0.5) * intensity;
            root.jitterY = (Math.random() - 0.5) * intensity;
            root.sparkIntensity = root.windupProgress > 0.2 ? (root.windupProgress - 0.2) * 2.2 : 0;
        }
    }

    NumberAnimation { id: windupAnim; target: root; property: "windupOffset"; from: 0; to: 150000; duration: 1600; easing.type: Easing.InQuint }

    ParallelAnimation {
        id: boomSequence
        onFinished: root.doLogin()
        NumberAnimation { target: root; property: "boomScale"; to: 35; duration: 150; easing.type: Easing.InQuad }
        NumberAnimation { target: root; property: "boomOpacity"; to: 1; duration: 120; easing.type: Easing.InQuad }
    }

    readonly property real smoothSecAngle: -((localTimeMS % 60000) / 60000) * 360 - windupOffset * 10
    readonly property real smoothMinAngle: -((localTimeMS % 3600000) / 3600000) * 360 - windupOffset * 5

    FontLoader { id: outfitFont; source: Qt.resolvedUrl("Outfit-Black.ttf") }

    // Grab focus once the lock surface is mapped.
    Timer { interval: 300; running: true; onTriggered: passInput.forceActiveFocus() }

    Component.onCompleted: {
        if (enableWindup)
            playLockReveal();
        else
            fadeIn.start();
    }
    NumberAnimation { id: fadeIn; target: root; property: "uiOpacity"; to: 1; duration: 350; easing.type: Easing.OutCubic }

    Item {
        id: blastContainer
        anchors.fill: parent
        opacity: root.uiOpacity
        x: root.jitterX
        y: root.jitterY
        transform: Scale { origin.x: 400 * root.s; origin.y: blastContainer.height * 0.5; xScale: root.boomScale; yScale: root.boomScale }

        Item {
            id: clockContainer
            anchors { left: parent.left; verticalCenter: parent.verticalCenter }
            width: 800 * root.s
            height: parent.height
            readonly property real cx: 40 * root.s
            readonly property real cy: height * 0.5
            readonly property real minR: 320 * root.s
            readonly property real secR: 480 * root.s

            Rectangle {
                id: indicatorPill
                z: 1
                x: clockContainer.cx + 230 * root.s
                anchors.verticalCenter: parent.verticalCenter
                width: 330 * root.s
                height: 90 * root.s
                radius: 45 * root.s
                color: root.pillColor
                border { color: root.pillBorder; width: 1 * root.s }

                Rectangle {
                    x: 170 * root.s
                    anchors.verticalCenter: parent.verticalCenter
                    width: 1 * root.s
                    height: 35 * root.s
                    color: root.pillInnerLine
                }
            }

            // Sparks thrown off as the dials wind up.
            Repeater {
                model: 60
                delegate: Rectangle {
                    z: 50
                    property real randA: Math.random() * 6.28
                    property real randV: 400 * root.s + Math.random() * 900 * root.s
                    x: clockContainer.cx + 400 * root.s + Math.cos(randA) * randV * root.sparkIntensity
                    y: clockContainer.cy + Math.sin(randA) * randV * root.sparkIntensity
                    width: (1 + Math.random() * 2) * root.s
                    height: (1 + 12 * root.sparkIntensity) * root.s
                    rotation: randA * 180 / Math.PI + 90
                    radius: width / 2
                    color: root.sparkColor
                    opacity: root.sparkIntensity * (Math.random() > 0.4 ? 1 : 0.2)
                    visible: root.sparkIntensity > 0
                }
            }

            // Minute dial.
            Repeater {
                model: 60
                delegate: DialTick {
                    angle: root.smoothMinAngle
                    s: root.s; isLight: root.isLight; fontFamily: outfitFont.name
                    cx: clockContainer.cx; cy: clockContainer.cy
                    radius: clockContainer.minR
                    tickWidth: isMajor ? 2 : 1
                    tickHeight: isMajor ? 18 : 10
                    labelInset: 35
                    labelSize: 22
                }
            }

            // Second dial.
            Repeater {
                model: 60
                delegate: DialTick {
                    angle: root.smoothSecAngle
                    s: root.s; isLight: root.isLight; fontFamily: outfitFont.name
                    cx: clockContainer.cx; cy: clockContainer.cy
                    radius: clockContainer.secR
                    tickWidth: isMajor ? 1.5 : 1
                    tickHeight: isMajor ? 13 : 8
                    labelInset: 30
                    labelSize: 16
                }
            }

            Text {
                anchors { right: indicatorPill.left; rightMargin: 40 * root.s; verticalCenter: parent.verticalCenter }
                text: String(root.now.getHours()).padStart(2, "0")
                color: root.mainText
                font { family: outfitFont.name; pixelSize: 110 * root.s; weight: Font.Black }
            }

            Column {
                anchors { left: indicatorPill.right; leftMargin: 110 * root.s; verticalCenter: parent.verticalCenter }
                spacing: 5 * root.s

                Text {
                    text: Qt.formatDate(root.now, "dd MMM yyyy").toUpperCase()
                    color: root.subColor
                    font { family: outfitFont.name; pixelSize: 13 * root.s; letterSpacing: 4 * root.s }
                }

                Text {
                    text: Qt.formatDate(root.now, "dddd").toUpperCase()
                    color: root.mainText
                    font { family: outfitFont.name; pixelSize: 18 * root.s; letterSpacing: 8 * root.s; weight: Font.Bold }
                }
            }
        }
    }

    // The burst at the end of the wind-up.
    Rectangle {
        anchors.fill: parent
        z: 9999
        color: root.blastColor
        opacity: root.boomOpacity
    }

    Item {
        anchors.fill: parent
        opacity: root.uiOpacity * (root.boomOpacity > 0 ? 0 : 1)

        Row {
            anchors { right: parent.right; rightMargin: root.marginR; top: parent.top; topMargin: 50 * root.s }
            spacing: 25 * root.s

            LockAction {
                label: "Restart"
                s: root.s; fontFamily: outfitFont.name; mainText: root.mainText; dimText: root.dimText
                onClicked: Session.run("restart")
            }

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: 1 * root.s
                height: 10 * root.s
                color: root.pillBorder
            }

            LockAction {
                label: "Shut Down"
                s: root.s; fontFamily: outfitFont.name; mainText: root.mainText; dimText: root.dimText
                onClicked: Session.run("shutdown")
            }
        }

        Column {
            id: loginPanel
            anchors { right: parent.right; rightMargin: root.marginR; bottom: parent.bottom; bottomMargin: 80 * root.s }
            width: 350 * root.s
            spacing: 8 * root.s

            Text {
                width: parent.width
                height: 32 * root.s
                horizontalAlignment: Text.AlignRight
                text: User.name.toUpperCase()
                color: root.dimText
                font { family: outfitFont.name; pixelSize: 18 * root.s; weight: Font.Bold; letterSpacing: 8 * root.s }
            }

            Item {
                width: parent.width
                height: 30 * root.s

                TextInput {
                    id: passInput

                    property bool wasClicked: false

                    anchors.fill: parent
                    echoMode: TextInput.Password
                    passwordCharacter: "✦"
                    color: root.dimText
                    font { family: outfitFont.name; pixelSize: 14 * root.s; letterSpacing: 10 * root.s }
                    horizontalAlignment: TextInput.AlignRight
                    verticalAlignment: TextInput.AlignVCenter
                    focus: true
                    cursorVisible: false
                    cursorDelegate: Item { width: 0; height: 0 }
                    Keys.onReturnPressed: root.startLoginSequence()
                    Keys.onEnterPressed: root.startLoginSequence()
                    Keys.onEscapePressed: text = ""

                    Text {
                        anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                        text: root.inputHint
                        color: root.authInfo !== "" ? root.mainText : root.inputWaitColor
                        opacity: passInput.text.length === 0 ? 0.55 : 0
                        font { family: outfitFont.name; pixelSize: 10 * root.s; letterSpacing: 4 * root.s }
                        Behavior on opacity { NumberAnimation { duration: 400; easing.type: Easing.InOutSine } }
                    }

                    // A blinking needle in place of the text cursor.
                    Rectangle {
                        id: needleCursor
                        anchors.verticalCenter: parent.verticalCenter
                        x: passInput.cursorRectangle.x
                        width: 1.5 * root.s
                        height: 12 * root.s
                        color: root.mainText
                        visible: passInput.activeFocus && (passInput.text.length > 0 || passInput.wasClicked)

                        SequentialAnimation {
                            loops: Animation.Infinite
                            running: needleCursor.visible
                            NumberAnimation { target: needleCursor; property: "opacity"; from: 1; to: 0.1; duration: 450 }
                            NumberAnimation { target: needleCursor; property: "opacity"; from: 0.1; to: 1; duration: 450 }
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        passInput.forceActiveFocus();
                        passInput.wasClicked = true;
                    }
                }
            }

            Item {
                width: parent.width
                height: 40 * root.s

                Text {
                    id: loginBtn
                    anchors { right: parent.right; rightMargin: btnArea.containsMouse ? 25 * root.s : 0 }
                    text: "UNLOCK"
                    color: btnArea.containsMouse ? root.mainText : root.dimText
                    font { family: outfitFont.name; pixelSize: 11 * root.s; letterSpacing: 4 * root.s; weight: Font.Bold }
                    Behavior on anchors.rightMargin { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                }

                Text {
                    anchors { left: loginBtn.right; leftMargin: 8 * root.s; verticalCenter: loginBtn.verticalCenter }
                    text: "✦"
                    color: root.mainText
                    opacity: btnArea.containsMouse ? 1 : 0
                    font.pixelSize: 10 * root.s
                    Behavior on opacity { NumberAnimation { duration: 200 } }
                }

                MouseArea {
                    id: btnArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.startLoginSequence()
                }
            }

            Text {
                id: errText
                width: parent.width
                height: 15 * root.s
                verticalAlignment: Text.AlignBottom
                horizontalAlignment: Text.AlignRight
                color: "#ff4444"
                font { family: outfitFont.name; pixelSize: 10 * root.s; letterSpacing: 2 * root.s }
            }
        }
    }

    Timer { id: boomTriggerTimer; interval: 1450; onTriggered: boomSequence.start() }

    function startLoginSequence() {
        if (isWindup || _submitted)
            return;
        // PAM never answers an empty password; the burst would stay up.
        if (passInput.text.length === 0) {
            errText.text = "";
            passInput.forceActiveFocus();
            return;
        }
        if (enableWindup) {
            isWindup = true;
            windupAnim.start();
            boomTriggerTimer.start();
        } else {
            doLogin();
        }
    }

    property bool _submitted: false

    function doLogin() {
        if (_submitted)
            return;
        _submitted = true;
        authInfo = "";
        submit(passInput.text);
        authWatchdog.restart();
    }

    function clearUnlockFlash() {
        _submitted = false;
        isWindup = false;
        windupAnim.stop();
        boomTriggerTimer.stop();
        boomSequence.stop();
        windupOffset = 0;
        boomScale = 1;
        boomOpacity = 0;
        sparkIntensity = 0;
    }

    // The burst stays up until PAM answers; this lowers it if it never does.
    Timer {
        id: authWatchdog
        interval: 8000
        onTriggered: {
            root.clearUnlockFlash();
            root.authInfo = "";
            errText.text = "";
            passInput.text = "";
            passInput.forceActiveFocus();
        }
    }

    function succeed() {
        authWatchdog.stop();
        if (enableWindup)
            playUnlockReveal();
    }

    function fail() {
        authWatchdog.stop();
        clearUnlockFlash();
        authInfo = "";
        errText.text = "ACCESS DENIED";
        passInput.text = "";
        passInput.forceActiveFocus();
        shake.start();
    }

    function inform(message) {
        authInfo = message || "";
        errText.text = authInfo.toUpperCase();
    }

    SequentialAnimation {
        id: shake
        NumberAnimation { target: loginPanel; property: "anchors.rightMargin"; from: root.marginR; to: root.marginR + 10 * root.s; duration: 50; easing.type: Easing.InOutSine }
        NumberAnimation { target: loginPanel; property: "anchors.rightMargin"; to: root.marginR - 10 * root.s; duration: 50; easing.type: Easing.InOutSine }
        NumberAnimation { target: loginPanel; property: "anchors.rightMargin"; to: root.marginR; duration: 50; easing.type: Easing.InOutSine }
    }

    // Circular reveal: a background-coloured ring whose hole grows to show the lock screen, and
    // shrinks to cover it again on unlock.
    readonly property real revealDiag: Math.sqrt(width * width + height * height)
    property real revealR: 0
    property bool revealActive: false

    Rectangle {
        z: 20000
        anchors.centerIn: parent
        visible: root.revealActive
        width: 2 * (root.revealR + root.revealDiag)
        height: width
        radius: width / 2
        color: "transparent"
        border { width: root.revealDiag; color: root.bgColor }
    }

    NumberAnimation {
        id: revealIn
        target: root; property: "revealR"
        from: 0; to: root.revealDiag; duration: 1150; easing.type: Easing.InOutCubic
        onFinished: root.revealActive = false
    }

    NumberAnimation {
        id: revealOut
        target: root; property: "revealR"
        from: root.revealDiag; to: 0; duration: 560; easing.type: Easing.InOutCubic
    }

    function playLockReveal() {
        revealOut.stop();
        uiOpacity = 1;
        revealR = 0;
        revealActive = true;
        revealIn.restart();
    }

    function playUnlockReveal() {
        revealIn.stop();
        revealR = revealDiag;
        revealActive = true;
        revealOut.restart();
    }
}
