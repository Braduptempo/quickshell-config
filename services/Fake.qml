// Fake.qml
// For testing what the shell shows in states you don't want to cause for
// real: QS_FAKE=wifi-off,no-internet,portal,bt-off,no-audio,load. Only the UI
// pretends; nothing is switched off.
pragma Singleton

import QtQuick
import Quickshell

Singleton {
  readonly property var flags: (Quickshell.env("QS_FAKE") ?? "").split(",").map(f => f.trim()).filter(f => f !== "")

  function has(flag: string): bool {
    return flags.indexOf(flag) >= 0;
  }
}
