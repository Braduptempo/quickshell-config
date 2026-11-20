// Config.qml
// User settings, stored in settings.json next to shell.qml.
// Changes from the UI are written back immediately, and edits to the file
// are picked up live. settings.json is per machine and not in git.
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
  id: root

  component AppearanceSettings: JsonObject {
    property string theme: "Mocha"
    // Empty means: use the theme's own accent
    property string accent: ""
    property real glass: 0.45
    property string fontFamily: "JetBrains Mono"
    property real fontScale: 1.0
  }

  component AnimationSettings: JsonObject {
    // 0 off, 1 slow, 2 normal, 3 fast
    property int speed: 2
    // "slide", "fade" or "scale"
    property string panelStyle: "slide"
  }

  component BarSettings: JsonObject {
    property string position: "top"
    property string style: "floating"
  }

  component LockSettings: JsonObject {
    // Lock after this many minutes without input; 0 = never
    property int idleMinutes: 10
    // Show what's playing on the lock screen
    property bool showMedia: true
    // Show how many notifications came in
    property bool showNotifications: true
  }

  property alias appearance: adapter.appearance
  property alias animations: adapter.animations
  property alias bar: adapter.bar
  property alias lock: adapter.lock

  FileView {
    id: file
    path: Quickshell.shellPath("settings.json")
    watchChanges: true
    onFileChanged: reload()
    onAdapterUpdated: writeAdapter()
    onLoadFailed: error => {
      // First start: write the defaults so there is a file to edit
      if (error === FileViewError.FileNotFound) writeAdapter();
    }

    JsonAdapter {
      id: adapter

      property AppearanceSettings appearance: AppearanceSettings {}

      property AnimationSettings animations: AnimationSettings {}

      property BarSettings bar: BarSettings {}

      property LockSettings lock: LockSettings {}
    }
  }
}
