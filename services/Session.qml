// Session.qml
// Small system switches for quick settings: caffeine, night light,
// brightness and power profiles. Each one checks whether its tool exists,
// so the quick settings only show what works on this machine
// (e.g. brightness on the laptop, not on a desktop monitor).
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
  id: root

  // --- Caffeine: keeps the screen awake (IdleInhibitor in the bar) ---------
  property bool caffeine: false

  // --- Night light (hyprsunset) ---------------------------------------------
  property bool nightLightAvailable: false
  property bool nightLight: false
  property int nightLightTemperature: 4000

  Process {
    command: ["sh", "-c", "command -v hyprsunset"]
    running: true
    onExited: code => root.nightLightAvailable = code === 0
  }

  Process {
    // Runs while night light is on; stopping it restores normal colours
    command: ["hyprsunset", "-t", String(root.nightLightTemperature)]
    running: root.nightLightAvailable && root.nightLight
  }

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
