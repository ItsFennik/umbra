import QtQuick
import qs.components
import qs.config
import qs.services

// Current track in the menu bar: cover art and title. Clicking opens the Now Playing popout,
// scrolling skips tracks. Stays while paused. Size, text width and text are set in Settings.
BarButton {
    id: root

    required property var screen
    readonly property var player: Media.player
    readonly property int textSize: Math.max(9, Math.min(20, Settings.barMediaSize))

    visible: Settings.barShowMedia && player !== null
    active: Panels.current === "media"
    onClicked: Panels.toggle("media", root.screen, root.mapToItem(null, root.width / 2, 0).x)
    onWheel: event => {
        if (event.angleDelta.y > 0 && root.player.canGoPrevious)
            root.player.previous();
        else if (event.angleDelta.y < 0 && root.player.canGoNext)
            root.player.next();
    }

    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: Math.min(Theme.barHeight - 8, root.textSize + 5)
        height: width
        radius: 3
        color: Theme.tileOff
        clip: true

        Icon {
            anchors.centerIn: parent
            visible: art.status !== Image.Ready
            name: "music"
            size: Math.round(parent.width * 0.65)
        }

        Image {
            id: art
            anchors.fill: parent
            source: root.player?.trackArtUrl ?? ""
            sourceSize { width: 48; height: 48 }
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
        }
    }

    Text {
        anchors.verticalCenter: parent.verticalCenter
        visible: Settings.barMediaText !== "none"
        width: Math.min(implicitWidth, Settings.barMediaWidth)
        text: {
            const title = root.player?.trackTitle || root.player?.identity || "";
            const artist = root.player?.trackArtist ?? "";
            return Settings.barMediaText === "full" && artist !== "" ? title + " — " + artist : title;
        }
        elide: Text.ElideRight
        color: Theme.text
        font { family: Theme.font; pixelSize: root.textSize; weight: Theme.weight(Font.Medium) }
    }
}
