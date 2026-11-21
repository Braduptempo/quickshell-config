// Osd.qml
// What the on-screen pop-up shows right now. Anything can call show();
// the pop-up stays 1.5 s after the last change.
pragma Singleton

import QtQuick
import Quickshell

Singleton {
  id: root

  property bool shown: false
  property string icon: "volume"
  property string title: ""
  property string subtitle: ""
  // 0…1 for a bar, or -1 for no bar
  property real value: -1
  property string valueText: ""
  // "accent", "warn" or "error": colour of the icon circle
  property string tone: "accent"
  // Short code in the circle instead of an icon (keyboard layout)
  property string badge: ""

  function show(options: var): void {
    icon = options.icon ?? "volume";
    title = options.title ?? "";
    subtitle = options.subtitle ?? "";
    value = options.value ?? -1;
    valueText = options.valueText ?? "";
    tone = options.tone ?? "accent";
    badge = options.badge ?? "";
    shown = true;
    hideTimer.restart();
  }

  Timer {
    id: hideTimer
    interval: 1500
    onTriggered: root.shown = false
  }
}
