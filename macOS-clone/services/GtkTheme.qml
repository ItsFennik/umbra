pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// GTK theme and wallpaper colors for GTK apps.
//   theme   -> gsettings gtk-theme and gtk-{3,4}.0/settings.ini. Themes with a "-dark" sibling
//              (adw-gtk3 / adw-gtk3-dark) are one family whose variant follows Light/Dark.
//   colors  -> with Settings.gtkMatugen, the matugen palette is written as libadwaita named colors
//              into a marked block at the end of gtk-{3,4}.0/gtk.css, overriding earlier imports.
Singleton {
    id: root

    // [{ name, light, dark }]; light or dark is "" when the theme has only one variant.
    property var families: []
    property string theme: ""
    readonly property var family: families.find(f => f.light === theme || f.dark === theme) ?? null
    readonly property bool colorsActive: Settings.gtkMatugen && Matugen.available && palette.primary !== undefined
    readonly property var palette: Matugen.scheme[Appearance.dark ? "dark" : "light"] ?? {}

    readonly property string home: Quickshell.env("HOME")
    readonly property string dataHome: Quickshell.env("XDG_DATA_HOME") || home + "/.local/share"
    readonly property string configHome: Quickshell.env("XDG_CONFIG_HOME") || home + "/.config"

    function refresh() {
        scan.running = false;
        scan.running = true;
    }

    function variant(f) {
        return (Appearance.dark ? f.dark || f.light : f.light || f.dark);
    }

    function setFamily(f) {
        apply(variant(f));
    }

    function apply(name) {
        if (name === "")
            return;
        theme = name;
        Quickshell.execDetached(["sh", "-c", `
            gsettings set org.gnome.desktop.interface gtk-theme "$1"
            for v in gtk-3.0 gtk-4.0; do
                f="$2/$v/settings.ini"
                [ -f "$f" ] || continue
                sed -i -e "s|^gtk-theme-name=.*|gtk-theme-name=$1|" -e "s|^gtk-application-prefer-dark-theme=.*|gtk-application-prefer-dark-theme=$3|" "$f"
            done
            # Point nwg-look style gtk-4.0 links at the new theme.
            for d in "$4/themes/$1" "$5/.themes/$1" "/usr/share/themes/$1"; do
                [ -d "$d/gtk-4.0" ] || continue
                for l in assets gtk-dark.css; do
                    [ -L "$2/gtk-4.0/$l" ] && [ -e "$d/gtk-4.0/$l" ] && ln -sfn "$d/gtk-4.0/$l" "$2/gtk-4.0/$l"
                done
                break
            done`, "sh", name, configHome, Appearance.dark ? "1" : "0", dataHome, home]);
    }

    function css(gtk4) {
        const c = palette;
        const pairs = [
            ["accent_color", c.primary], ["accent_bg_color", c.primary], ["accent_fg_color", c.on_primary],
            ["destructive_color", c.error], ["destructive_bg_color", c.error], ["destructive_fg_color", c.on_error],
            ["error_color", c.error], ["error_bg_color", c.error], ["error_fg_color", c.on_error],
            ["success_color", c.tertiary], ["success_bg_color", c.tertiary_container], ["success_fg_color", c.on_tertiary_container],
            ["warning_color", c.secondary], ["warning_bg_color", c.secondary_container], ["warning_fg_color", c.on_secondary_container],
            ["window_bg_color", c.surface], ["window_fg_color", c.on_surface],
            ["view_bg_color", c.surface_container_low], ["view_fg_color", c.on_surface],
            ["headerbar_bg_color", c.surface_container], ["headerbar_fg_color", c.on_surface],
            ["headerbar_backdrop_color", c.surface], ["headerbar_border_color", c.outline_variant],
            ["popover_bg_color", c.surface_container_high], ["popover_fg_color", c.on_surface],
            ["dialog_bg_color", c.surface_container_high], ["dialog_fg_color", c.on_surface],
            ["card_bg_color", c.surface_container], ["card_fg_color", c.on_surface],
            ["sidebar_bg_color", c.surface_container], ["sidebar_fg_color", c.on_surface],
            ["sidebar_backdrop_color", c.surface_container_low], ["sidebar_border_color", c.outline_variant],
            ["secondary_sidebar_bg_color", c.surface_container_low], ["secondary_sidebar_fg_color", c.on_surface],
            ["overview_bg_color", c.surface_container_low], ["overview_fg_color", c.on_surface],
            ["thumbnail_bg_color", c.surface_container_high], ["thumbnail_fg_color", c.on_surface],
            ["borders", c.outline_variant]
        ].filter(p => p[1] !== undefined);
        // Pre-libadwaita names, read by GTK 3 themes and older apps.
        const legacy = [
            ["theme_bg_color", "window_bg_color"], ["theme_fg_color", "window_fg_color"],
            ["theme_base_color", "view_bg_color"], ["theme_text_color", "view_fg_color"],
            ["theme_selected_bg_color", "accent_bg_color"], ["theme_selected_fg_color", "accent_fg_color"],
            ["theme_unfocused_bg_color", "window_bg_color"], ["theme_unfocused_fg_color", "window_fg_color"],
            ["theme_unfocused_base_color", "view_bg_color"], ["theme_unfocused_text_color", "view_fg_color"],
            ["theme_unfocused_selected_bg_color", "accent_bg_color"], ["theme_unfocused_selected_fg_color", "accent_fg_color"]
        ];
        let out = pairs.map(p => `@define-color ${p[0]} ${p[1]};`).concat(legacy.map(p => `@define-color ${p[0]} @${p[1]};`)).join("\n");
        // libadwaita 1.6+ reads CSS variables; GTK 3 would reject them.
        if (gtk4)
            out += "\n:root {\n" + pairs.map(p => `    --${p[0].replace(/_/g, "-")}: ${p[1]};`).join("\n") + "\n}";
        return out;
    }

    // Rewrites (or removes) the color block; GTK 3 apps reload when the theme name blips.
    function writeColors() {
        const on = colorsActive;
        Quickshell.execDetached(["sh", "-c", `
            changed=0
            for v in gtk-3.0 gtk-4.0; do
                f="$1/$v/gtk.css"
                mkdir -p "$1/$v"
                if [ -L "$f" ]; then
                    t=$(readlink -f "$f"); rm "$f"
                    printf '@import url("file://%s");\\n' "$t" > "$f"
                fi
                [ -f "$f" ] || : > "$f"
                new=$(sed '/\\/\\* umbra colors begin \\*\\//,/\\/\\* umbra colors end \\*\\//d' "$f")
                if [ "$2" = on ]; then
                    [ "$v" = gtk-3.0 ] && block="$3" || block="$4"
                    new=$(printf '%s\\n\\n/* umbra colors begin */\\n%s\\n/* umbra colors end */' "$new" "$block")
                fi
                [ "$new" = "$(cat "$f")" ] && continue
                printf '%s\\n' "$new" > "$f"
                changed=1
            done
            if [ $changed = 1 ]; then
                t="$5"
                [ -n "$t" ] || t=$(gsettings get org.gnome.desktop.interface gtk-theme | tr -d "'")
                gsettings set org.gnome.desktop.interface gtk-theme Default
                sleep 0.2
                gsettings set org.gnome.desktop.interface gtk-theme "$t"
            fi`, "sh", configHome, on ? "on" : "off", on ? css(false) : "", on ? css(true) : "", theme]);
    }

    onColorsActiveChanged: colorTimer.restart()
    onPaletteChanged: if (colorsActive) colorTimer.restart()

    Connections {
        target: Appearance
        function onDarkChanged() {
            if (root.family && root.variant(root.family) !== root.theme)
                root.apply(root.variant(root.family));
        }
    }

    // Palette, mode and toggle often change together; write once. gtk.css is only rewritten
    // (and GTK 3 apps reloaded) when the block is out of date.
    Timer {
        id: colorTimer
        interval: 400
        running: true
        // While the toggle is on but the palette is still generating, keep the old block.
        onTriggered: if (root.colorsActive || !Settings.gtkMatugen) root.writeColors()
    }

    Component.onCompleted: refresh()

    // Prints every theme with GTK 3 or 4 styles, then "current <gtk-theme>".
    Process {
        id: scan
        command: ["sh", "-c", `
            for d in "$1/themes"/* "$2/.themes"/* /usr/share/themes/*; do
                [ -d "$d/gtk-3.0" ] || [ -d "$d/gtk-4.0" ] || continue
                echo "theme $(basename "$d")"
            done
            echo "current $(gsettings get org.gnome.desktop.interface gtk-theme 2>/dev/null | tr -d "'")"`, "sh", root.dataHome, root.home]
        stdout: StdioCollector {
            onStreamFinished: {
                const names = ["Adwaita", "Adwaita-dark"];
                for (const line of text.trim().split("\n")) {
                    const space = line.indexOf(" ");
                    const kind = line.slice(0, space), name = line.slice(space + 1).trim();
                    if (kind === "theme" && name !== "Default" && name !== "Emacs" && !names.includes(name))
                        names.push(name);
                    else if (kind === "current")
                        root.theme = name;
                }
                const families = [];
                for (const name of names) {
                    const m = name.match(/^(.*)-dark$/i);
                    if (m && names.includes(m[1]))
                        continue;
                    const dark = names.find(n => n.toLowerCase() === name.toLowerCase() + "-dark") ?? "";
                    families.push(m ? { name: m[1], light: "", dark: name } : { name, light: name, dark });
                }
                root.families = families.sort((a, b) => a.name.localeCompare(b.name));
            }
        }
    }
}
