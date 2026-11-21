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

  function apply(): void {
    // Only the Lua config has named rules to replace
    if (!Hyprland.usingLua) return;
    Quickshell.execDetached(["hyprctl", "eval",
      "hl.layer_rule({ name = \"quickshell-glass\", match = { namespace = \"quickshell.*\" }, blur = " + (blur ? "true" : "false")
      + ", ignore_alpha = 0.2, no_anim = true })"]);
  }

  onBlurChanged: apply()
  Component.onCompleted: apply()
}
