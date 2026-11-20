// Session.qml
// Small system switches for quick settings: caffeine, night light,
// brightness and power profiles. Each one checks whether its tool exists,
// so the quick settings only show what works on this machine
// (e.g. brightness on the laptop, not on a desktop monitor).
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import "../config"

Singleton {
  id: root

  // --- Caffeine: keeps the screen awake (IdleInhibitor in the bar) ---------
  property bool caffeine: false

  // --- Night light (hyprsunset) ---------------------------------------------
  // Turned on by hand (quick settings) or by the schedule in Settings →
  // Night light; paused during a screen recording when that's chosen.
  property bool nightLightAvailable: false
  property bool nightLight: false
  readonly property int nightLightTemperature: Config.nightLight.temperature
  readonly property bool nightLightPaused: Config.nightLight.pauseWhileRecording && Capture.recording
  readonly property bool nightLightActive: nightLightAvailable && nightLight && !nightLightPaused

  Process {
    command: ["sh", "-c", "command -v hyprsunset"]
    running: true
    onExited: code => root.nightLightAvailable = code === 0
  }

  Process {
    id: sunset
    // Runs while night light is on; stopping it restores normal colours
    command: ["hyprsunset", "-t", String(root.nightLightTemperature)]
    running: root.nightLightActive
  }

  // A new temperature: start hyprsunset again with it
  onNightLightTemperatureChanged: if (nightLightActive) sunsetRestart.restart()

  Timer {
    id: sunsetRestart
    interval: 250
    onTriggered: {
      sunset.running = false;
      sunset.running = Qt.binding(() => root.nightLightActive);
    }
  }

  // "20:00" -> minutes after midnight, or -1
  function minutesOf(text: string): int {
    const m = text.match(/^(\d{1,2}):(\d{2})$/);
    return m ? parseInt(m[1]) * 60 + parseInt(m[2]) : -1;
  }

  // Inside the scheduled hours (also over midnight)
  readonly property bool nightLightScheduled: {
    if (Config.nightLight.schedule !== "custom") return false;
    const a = minutesOf(Config.nightLight.from), b = minutesOf(Config.nightLight.to);
    if (a < 0 || b < 0 || a === b) return false;
    const d = Time.date;
    const now = d.getHours() * 60 + d.getMinutes();
    return a < b ? now >= a && now < b : now >= a || now < b;
  }

  // The schedule switches it at the start and end; in between you can still
  // turn it off or on by hand
  onNightLightScheduledChanged: nightLight = nightLightScheduled
  Component.onCompleted: if (nightLightScheduled) nightLight = true

  // --- Brightness (brightnessctl, backlight only) ----------------------------
  property bool brightnessAvailable: false
  property real brightness: 0.5

  // Re-read after brightness keys changed it outside the shell
  function refreshBrightness(): void {
    getBrightnessProc.running = true;
  }

  function setBrightness(value: real): void {
    brightness = Math.max(0.01, Math.min(1, value));
    setBrightnessProc.command = ["brightnessctl", "-c", "backlight", "set", Math.round(brightness * 100) + "%"];
    setBrightnessProc.running = true;
  }

  Process {
    id: getBrightnessProc
    // Machine-readable: device,class,current,percent,max
    command: ["sh", "-c", "command -v brightnessctl >/dev/null && brightnessctl -m -c backlight info"]
    running: true
    stdout: StdioCollector {
      onStreamFinished: {
        const parts = text.trim().split(",");
        if (parts.length >= 4) {
          root.brightnessAvailable = true;
          root.brightness = parseInt(parts[3]) / 100;
        }
      }
    }
  }

  Process {
    id: setBrightnessProc
  }

  // --- Power profiles (power-profiles-daemon) --------------------------------
  property bool profilesAvailable: false
  // "power-saver", "balanced" or "performance"
  property string profile: "balanced"

  function setProfile(name: string): void {
    profile = name;
    setProfileProc.command = ["powerprofilesctl", "set", name];
    setProfileProc.running = true;
  }

  Process {
    command: ["sh", "-c", "command -v powerprofilesctl >/dev/null && powerprofilesctl get"]
    running: true
    stdout: StdioCollector {
      onStreamFinished: {
        const value = text.trim();
        if (value !== "") {
          root.profilesAvailable = true;
          root.profile = value;
        }
      }
    }
  }

  Process {
    id: setProfileProc
  }
}
