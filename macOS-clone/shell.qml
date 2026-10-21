//@ pragma UseQApplication
//@ pragma IconTheme WhiteSur-dark
import QtQuick
import Quickshell
import qs.services
import qs.modules.bar
import qs.modules.controlcenter
import qs.modules.dock
import qs.modules.launcher
import qs.modules.menu
import qs.modules.notifications
import qs.modules.overview
import qs.modules.settings
import qs.modules.wallpaper

ShellRoot {
    WallpaperLayer {}
    WallpaperPicker {}

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
    NotificationCenter {}
    Banners {}
    Overview {}
    ContextMenuLayer {}
    SettingsApp {}
}
