pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

// Current wallpaper and picker folder, stored in $XDG_STATE_HOME/umbra/wallpaper.json.
// Config seeds both on first run.
// A live wallpaper is a video played behind the desktop by mpvpaper; while one is set,
// WallpaperLayer stops drawing the still image and matugen reads a frame of the video.
Singleton {
    id: root

    readonly property string path: file.loaded && adapter.path !== "" ? adapter.path : Config.wallpaper
    readonly property string directory: file.loaded && adapter.directory !== "" ? adapter.directory : Config.wallpaperDirectory
    readonly property string live: file.loaded ? adapter.live : ""
    readonly property string liveDirectory: file.loaded && adapter.liveDirectory !== "" ? adapter.liveDirectory : Config.liveWallpaperDirectory
    property bool mpvpaperAvailable: false
    // Still frame of the live wallpaper, once extracted.
    property string liveFrame: ""
    // Image the wallpaper colors come from.
    readonly property string colorSource: live !== "" ? liveFrame : path

    readonly property string thumbnailDirectory: (Quickshell.env("XDG_CACHE_HOME") || Quickshell.env("HOME") + "/.cache") + "/umbra/live"

    function expand(p) {
        return p.startsWith("~/") ? Quickshell.env("HOME") + p.slice(1) : p;
    }

    // Choosing a still image also turns the live wallpaper off.
    function set(newPath) {
        adapter.path = expand(newPath);
        adapter.live = "";
        save();
    }

    function setDirectory(newDirectory) {
        adapter.directory = expand(newDirectory);
        save();
    }

    function setLive(video) {
        adapter.live = expand(video);
        save();
    }

    function clearLive() {
        adapter.live = "";
        save();
    }

    function setLiveDirectory(newDirectory) {
        adapter.liveDirectory = expand(newDirectory);
        save();
    }

    // Cached thumbnail path for a video; thumbnailCommand writes it.
    function thumbnail(video) {
        return thumbnailDirectory + "/" + Qt.md5(video) + ".jpg";
    }

    function thumbnailCommand(video) {
        return ["sh", "-c", 'mkdir -p "$(dirname "$2")" && { [ -s "$2" ] || ffmpegthumbnailer -i "$1" -o "$2" -s 480 -q 8 2>/dev/null || ffmpeg -loglevel error -y -ss 1 -i "$1" -frames:v 1 -vf scale=480:-2 "$2"; }', "sh", video, thumbnail(video)];
    }

    function save() {
        if (adapter.path === "")
            adapter.path = path;
        if (adapter.directory === "")
            adapter.directory = directory;
        if (adapter.liveDirectory === "")
            adapter.liveDirectory = liveDirectory;
        file.loaded = true;
        file.writeAdapter();
    }

    function restartPlayer() {
        player.running = false;
        if (live === "" || !mpvpaperAvailable)
            return;
        // -p pauses playback while the wallpaper is covered.
        player.command = ["mpvpaper", "-p", "-o", "no-audio loop hwdec=auto panscan=1.0", "ALL", live];
        player.running = true;
    }

    function extractFrame() {
        liveFrame = "";
        framer.running = false;
        if (live === "")
            return;
        framer.video = live;
        framer.command = thumbnailCommand(live);
        framer.running = true;
    }

    onLiveChanged: {
        restartPlayer();
        extractFrame();
    }
    onMpvpaperAvailableChanged: restartPlayer()

    Process {
        running: true
        command: ["sh", "-c", "command -v mpvpaper"]
        onExited: code => root.mpvpaperAvailable = code === 0
    }

    Process {
        id: player
        stderr: StdioCollector {
            onStreamFinished: if (text.trim() !== "") console.warn("Umbra: mpvpaper:", text.trim())
        }
    }

    Process {
        id: framer

        property string video

        onExited: code => {
            if (code === 0 && video === root.live)
                root.liveFrame = root.thumbnail(video);
            else if (code !== 0)
                console.warn("Umbra: cannot read a frame of", video);
        }
    }

    FileView {
        id: file

        property bool loaded: false

        path: (Quickshell.env("XDG_STATE_HOME") || Quickshell.env("HOME") + "/.local/state") + "/umbra/wallpaper.json"
        atomicWrites: true
        printErrors: false
        onLoaded: loaded = true
        onLoadFailed: error => {
            if (error !== FileViewError.FileNotFound)
                console.warn("Umbra: cannot read wallpaper state:", FileViewError.toString(error));
        }

        JsonAdapter {
            id: adapter
            property string path: ""
            property string directory: ""
            property string live: ""
            property string liveDirectory: ""
        }
    }
}
