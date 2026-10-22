//@ pragma UseQApplication
//@ pragma IconTheme WhiteSur-dark
// Memory: load only NVIDIA's EGL vendor (glvnd otherwise also maps Mesa and LLVM), and render
// every window on the GUI thread instead of one render thread and GL context per window.
//@ pragma DefaultEnv __EGL_VENDOR_LIBRARY_FILENAMES=/usr/share/glvnd/egl_vendor.d/10_nvidia.json
//@ pragma DefaultEnv QSG_RENDER_LOOP=basic
import QtQuick
import Quickshell
import qs.services
import qs.modules.bar
import qs.modules.controlcenter
import qs.modules.dock
import qs.modules.launcher
import qs.modules.lock
import qs.modules.media
import qs.modules.menu
import qs.modules.notifications
import qs.modules.overview
import qs.modules.power
import qs.modules.settings
import qs.modules.wallpaper
import qs.modules.widgets

ShellRoot {
    WallpaperLayer {}
    WallpaperPicker {}
    DesktopWidgets {}

    Variants {
        model: Quickshell.screens
        Bar {}
    }

    Variants {
        model: Settings.showDock ? Quickshell.screens : []
        Dock {}
    }

    Launcher {}
    ControlCenter {}
    MediaPanel {}
    NotificationCenter {}
    Banners {}
    Overview {}
    ContextMenuLayer {}
    SettingsApp {}
    PowerDialog {}
    LockScreen {}
}
