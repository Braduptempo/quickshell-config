// Appearance.qml
// Settings → Theme → Blur: turns Hyprland's blur behind the shell's glass on
// or off, at start and whenever it changes. The rule itself (and its default,
// on) is in hyprland/quickshell.lua; this replaces it by name with `hyprctl eval`.
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland
import "../config"

Singleton {
  id: root

  readonly property bool blur: Config.appearance.blur
  // Spotify's glass (rule in hyprland/quickshell.lua) follows Settings →
  // Theme → Panels: 0.5 there is 0.75 here, never below 0.7 so text stays
  // readable; solid without blur
  readonly property real appOpacity: blur ? Math.max(0.7, Math.min(1, 0.5 + 0.5 * Config.appearance.panelOpacity)) : 1

  function apply(): void {
    // Only the Lua config has named rules to replace
    if (!Hyprland.usingLua) return;
    Quickshell.execDetached(["hyprctl", "eval",
      "hl.layer_rule({ name = \"quickshell-glass\", match = { namespace = \"quickshell.*\" }, blur = " + (blur ? "true" : "false")
      + ", ignore_alpha = 0.2, no_anim = true })"]);
    const o = appOpacity.toFixed(2);
    Quickshell.execDetached(["hyprctl", "eval",
      "hl.window_rule({ name = \"spotify-glass\", match = { class = \"^([Ss]potify)$\" }, opacity = \"" + o + " " + o + "\" })"]);
  }

  onBlurChanged: apply()
  onAppOpacityChanged: apply()
  Component.onCompleted: apply()
}
