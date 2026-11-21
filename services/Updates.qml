// Updates.qml
// Package updates waiting: pacman (checkupdates, from pacman-contrib, which
// checks without root and without touching the system database) and the AUR
// (yay or paru). Checked at start and every hour; "Update now" opens the
// update in the chosen terminal.
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import "../config"

Singleton {
  id: root

  property var repo: []
  property var aur: []
  readonly property int count: repo.length + aur.length
  property bool checking: false
  property double checkedAt: 0
  property bool hasCheckupdates: true
  property string aurHelper: ""
  // A new kernel needs a restart before it's used
  readonly property bool kernel: repo.some(p => /^linux(-lts|-zen|-hardened)?$/.test(p.name))

  function check(): void {
    if (checking) return;
    checking = true;
    proc.running = true;
  }

  Timer {
    interval: 60 * 60 * 1000
    running: true
    repeat: true
    onTriggered: root.check()
  }

  // A minute after start, so it doesn't slow down logging in
  Timer {
    interval: 60 * 1000
    running: true
    onTriggered: root.check()
  }

  Process {
    id: proc
    command: ["sh", "-c",
      "if command -v checkupdates >/dev/null; then echo '@@REPO'; checkupdates 2>/dev/null; else echo '@@NOCHECK'; fi;" +
      "for h in paru yay; do if command -v $h >/dev/null; then echo \"@@AUR $h\"; $h -Qua 2>/dev/null; break; fi; done"]
    stdout: StdioCollector {
      onStreamFinished: {
        const repo = [], aur = [];
        let target = null;
        root.hasCheckupdates = !text.includes("@@NOCHECK");
        for (const line of text.split("\n")) {
          if (line === "@@REPO") { target = repo; continue; }
          if (line.startsWith("@@AUR")) { target = aur; root.aurHelper = line.slice(6).trim(); continue; }
          if (line.startsWith("@@")) { target = null; continue; }
          // "name 1.0-1 -> 1.1-1"
          const m = line.trim().match(/^(\S+)\s+(\S+)\s+->\s+(\S+)/);
          if (m && target) target.push({ name: m[1], from: m[2], to: m[3] });
        }
        root.repo = repo;
        root.aur = aur;
        root.checkedAt = Date.now();
      }
    }
    onExited: root.checking = false
  }

  // In a terminal: the AUR helper updates both, otherwise pacman
  function updateNow(): void {
    const cmd = aurHelper !== "" ? aurHelper + " -Syu" : "sudo pacman -Syu";
    DefaultApps.inTerminal(cmd + "; echo; echo 'Done. Press Enter to close.'; read _", []);
    recheck.restart();
  }

  // Check again a while after an update was started
  Timer {
    id: recheck
    interval: 5 * 60 * 1000
    onTriggered: root.check()
  }

  function ago(ms: real): string {
    if (!ms) return "not checked yet";
    const min = Math.floor((Date.now() - ms) / 60000);
    return "checked " + (min < 1 ? "just now" : min < 60 ? min + " min ago" : Math.floor(min / 60) + " h ago");
  }
}
