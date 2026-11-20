// Displays.qml
// Monitor resolution, refresh rate, scale, rotation and arrangement, for
// Settings → Displays.
//
// Changes are tried first: Displays.apply(draft) sets them with `hyprctl eval`
// and starts a 15 s countdown. keep() saves them to hyprland/monitors.lua
// (loaded by hyprland/quickshell.lua, per machine, not in git); doing nothing
// or revert() puts the old settings back, so a mode your monitor can't show
// never leaves you with a black screen.
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
  id: root

  // [{ name, description, width, height, refresh, x, y, scale, transform,
  //    disabled, modes: [{ width, height, refresh, mode }] }]
  property var monitors: []

  function refresh(): void {
    query.running = true;
  }

  Component.onCompleted: refresh()

  Process {
    id: query
    command: ["hyprctl", "monitors", "all", "-j"]
    stdout: StdioCollector {
      onStreamFinished: {
        let list = [];
        try {
          list = JSON.parse(text);
        } catch (e) {
          return;
        }
        root.monitors = list.map(m => ({
          name: m.name,
          description: [m.make, m.model].filter(s => s && s !== "").join(" ") || m.description,
          width: m.width,
          height: m.height,
          refresh: m.refreshRate,
          x: m.x,
          y: m.y,
          scale: m.scale,
          transform: m.transform,
          disabled: m.disabled,
          modes: (m.availableModes ?? []).map(s => {
            const p = s.match(/^(\d+)x(\d+)@([\d.]+)Hz$/);
            return p ? { width: parseInt(p[1]), height: parseInt(p[2]), refresh: parseFloat(p[3]), mode: p[1] + "x" + p[2] + "@" + p[3] } : null;
          }).filter(x => x)
        })).sort((a, b) => a.x - b.x);
      }
    }
  }

  // What hl.monitor({…}) needs for one monitor
  function lua(m: var): string {
    if (m.disabled) return "hl.monitor({ output = \"" + m.name + "\", disabled = true })";
    return "hl.monitor({ output = \"" + m.name + "\", mode = \"" + m.width + "x" + m.height + "@" + Number(m.refresh).toFixed(2)
         + "\", position = \"" + m.x + "x" + m.y + "\", scale = " + m.scale + ", transform = " + m.transform + " })";
  }

  // Lays monitors out left to right in the given order, top edges aligned
  function arrange(list: var): var {
    let x = 0;
    return list.map(m => {
      const rotated = m.transform % 2 === 1;
      const w = Math.round((rotated ? m.height : m.width) / m.scale);
      const placed = Object.assign({}, m, { x, y: 0 });
      if (!m.disabled) x += w;
      return placed;
    });
  }

  // --- Try, then keep or go back ----------------------------------------------------
  property bool confirming: false
  property int countdown: 0
  property string previousLua: ""
  property string pendingLua: ""
  property string error: ""

  function apply(draft: var): void {
    previousLua = monitors.map(lua).join("\n");
    pendingLua = draft.map(lua).join("\n");
    error = "";
    run(pendingLua);
    countdown = 15;
    confirming = true;
    revertTimer.restart();
  }

  function keep(): void {
    revertTimer.stop();
    confirming = false;
    save.running = true;
    refreshDelay.restart();
  }

  function revert(): void {
    revertTimer.stop();
    confirming = false;
    run(previousLua);
    refreshDelay.restart();
  }

  function run(code: string): void {
    evalProc.command = ["hyprctl", "eval", code];
    evalProc.running = true;
  }

  Process {
    id: evalProc
    stdout: StdioCollector {
      onStreamFinished: {
        if (text.trim().startsWith("error")) {
          root.error = text.trim();
          if (root.confirming) root.revert();
        }
      }
    }
  }

  Timer {
    id: revertTimer
    interval: 1000
    repeat: true
    onTriggered: {
      root.countdown--;
      if (root.countdown <= 0) root.revert();
    }
  }

  Timer {
    id: refreshDelay
    interval: 800
    onTriggered: root.refresh()
  }

  Process {
    id: save
    command: ["sh", "-c", "printf '%s\\n' \"$2\" > \"$1\"", "sh", Quickshell.shellPath("hyprland/monitors.lua"),
              "-- Made by Settings → Displays. Delete this file to use your own monitor config again.\n" + root.pendingLua]
  }

  // "1920 × 1080", "144 Hz"
  function resolution(m: var): string {
    return m.width + " × " + m.height;
  }

  function hz(refresh: real): string {
    return Math.round(refresh) + " Hz";
  }
}
