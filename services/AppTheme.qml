// AppTheme.qml
// Passes the shell's theme on to other apps: GTK 3/4 colours and dark/light,
// Spotify through Spicetify, and the SDDM login screen (see
// scripts/app-theme.py for what it writes).
// Runs at start and whenever the theme, accent, font, corners or wallpaper
// changes, a moment after the last change so dragging through themes doesn't
// run it for every step.
pragma Singleton

import QtQuick
import Quickshell
import "../config"

Singleton {
  id: root

  function hex(c: color): string {
    const h = v => Math.round(Math.max(0, Math.min(1, v)) * 255).toString(16).padStart(2, "0");
    return "#" + h(c.r) + h(c.g) + h(c.b);
  }

  // Everything the script needs, as one string: it changes when a colour does
  readonly property string palette: JSON.stringify({
    light: Theme.light,
    crust: hex(Theme.crust), base: hex(Theme.base), surface: hex(Theme.surface), overlay: hex(Theme.overlay),
    text: hex(Theme.text), subtext: hex(Theme.subtext), accent: hex(Theme.accent),
    good: hex(Theme.good), warn: hex(Theme.warn), error: hex(Theme.error),
    // For the login screen
    font: Config.appearance.fontFamily, roundness: Config.appearance.roundness, glass: Config.appearance.glass,
    wallpaper: Object.values(Wallpapers.current)[0] ?? ""
  })

  onPaletteChanged: debounce.restart()

  Timer {
    id: debounce
    interval: 1200
    onTriggered: Quickshell.execDetached(["python3", Quickshell.shellPath("scripts/app-theme.py"), root.palette])
  }

  Component.onCompleted: debounce.restart()
}
