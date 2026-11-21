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
    // Themes made in Settings → Theme: [{ name, light, crust, base, surface,
    // overlay, text, subtext, accent, good, warn, error }]
    property var customThemes: []
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
    // Mic, camera or screen in use
    property bool showPrivacy: true
    // Waiting package updates (pacman + AUR)
    property bool showUpdates: true
    // USB sticks and other removable drives
    property bool showDrives: true
  }

  component SoundSettings: JsonObject {
    // 1.0, or 1.5 to allow up to 150% (can distort)
    property real maxVolume: 1.0
    // A short click when the volume changes
    property bool feedback: false
    // Plugging in headphones (a new output) moves the sound there
    property bool followNewDevices: true
  }

  component CalendarSettings: JsonObject {
    // [{ name, url, color, enabled }]: ICS links (Google "secret address in
    // iCal format", Nextcloud, Outlook "publish calendar", holiday calendars)
    property var sources: []
    // Minutes between syncs; 0 = only by hand
    property int refreshMinutes: 15
    // "monday" or "sunday"
    property string weekStart: "monday"
  }

  component WeatherSettings: JsonObject {
    // The place you chose in Settings → Weather; empty = no weather
    property string place: ""
    property real latitude: 0
    property real longitude: 0
    // "celsius" or "fahrenheit"
    property string units: "celsius"
    property bool showOnLock: true
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

  component BatterySettings: JsonObject {
    // Percentages for the low and critical warnings; 0 turns that one off
    property int warnAt: 15
    property int criticalAt: 5
    // At critical, after a minute without a charger: "none", "suspend" or "hibernate"
    property string criticalAction: "none"
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
  property alias calendar: adapter.calendar
  property alias weather: adapter.weather
  property alias apps: adapter.apps
  property alias battery: adapter.battery

  property double lastWrite: 0

  Timer {
    id: writeDelay
    interval: 60
    onTriggered: {
      root.lastWrite = Date.now();
      file.writeAdapter();
    }
  }

  FileView {
    id: file
    path: Quickshell.shellPath("settings.json")
    watchChanges: true
    // Edits by hand are picked up; our own writes are not read back, or a
    // reload in the middle of setting several values (place, latitude,
    // longitude) would undo the ones set after the first write
    onFileChanged: if (Date.now() - root.lastWrite > 1000) reload()
    // Several changes in a row become one write
    onAdapterUpdated: writeDelay.restart()
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

      property CalendarSettings calendar: CalendarSettings {}

      property WeatherSettings weather: WeatherSettings {}

      property AppSettings apps: AppSettings {}

      property BatterySettings battery: BatterySettings {}
    }
  }
}
