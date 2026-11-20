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
    // "top" or "bottom"
    property string position: "top"
    // "floating" (a pill with a gap) or "attached" (edge to edge)
    property string style: "floating"
    property bool showMedia: true
    property bool showWindowTitle: false
    property bool showClipboard: true
    // Tray icons hidden behind an arrow until clicked
    property bool collapseTray: true
    property bool showDate: false
    // Monitors other than the first: "full", "light" (workspaces and clock) or "none"
    property string otherMonitors: "full"
  }

  component SoundSettings: JsonObject {
    // 1.0, or 1.5 to allow up to 150% (can distort)
    property real maxVolume: 1.0
    // A short click when the volume changes
    property bool feedback: false
    // Plugging in headphones (a new output) moves the sound there
    property bool followNewDevices: true
  }

  component DisplaySettings: JsonObject {
    // The monitor with the full bar; "" = the first one
    property string primary: ""
  }

  component AppSettings: JsonObject {
    // What the shell opens files and folders in a terminal with
    property string terminal: "kitty"
  }

  component NightLightSettings: JsonObject {
    // Kelvin while on: lower is warmer
    property int temperature: 4000
    // "manual" (quick settings only) or "custom" (on and off at these times)
    property string schedule: "manual"
    property string from: "20:00"
    property string to: "07:00"
    // Real colours in screen recordings
    property bool pauseWhileRecording: true
  }

  component NotificationSettings: JsonObject {
    property bool popups: true
    // Several pop-ups fold into one pile
    property bool stack: true
    // "top-right", "top-center" or "bottom-right"
    property string position: "top-right"
    // Seconds a pop-up stays when the app doesn't say
    property int duration: 5
    property bool sound: false
    // Do not disturb every day between these times ("22:00", "07:00"); "" = off
    property string quietFrom: ""
    property string quietTo: ""
    // Apps whose pop-ups are hidden (they still land in the clock panel)
    property var mutedApps: []
    // Apps that sent something, so the settings can list them
    property var knownApps: []
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
  property alias notifications: adapter.notifications
  property alias nightLight: adapter.nightLight
  property alias displays: adapter.displays
  property alias sound: adapter.sound
  property alias apps: adapter.apps

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

      property NotificationSettings notifications: NotificationSettings {}

      property NightLightSettings nightLight: NightLightSettings {}

      property DisplaySettings displays: DisplaySettings {}

      property SoundSettings sound: SoundSettings {}

      property AppSettings apps: AppSettings {}
    }
  }
}
