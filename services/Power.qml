// Power.qml
// What the power menu can do, and power actions scheduled for later.
//   Power.run("restart")              do it now
//   Power.schedule("poweroff", 30)    in 30 minutes; a reminder comes 1 minute before
//   Power.cancelSchedule()
// The menu itself is modules/power/PowerMenu.qml (Super + Esc).
//
// For testing: QS_POWER_DRYRUN=1 only shows a notification instead of
// locking, logging out, restarting or shutting down.
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
  id: root

  property bool open: false
  property ShellScreen screen: null
  property double closedAt: 0

  onOpenChanged: {
    if (open) refreshInfo();
    else closedAt = Date.now();
  }

  // Letter of the action to start with (`qs ipc call power open R`), "" = none
  property string initialKey: ""

  function toggle(onScreen: ShellScreen): void {
    if (open) {
      open = false;
    } else if (Date.now() - closedAt > 250) {
      initialKey = "";
      screen = onScreen;
      open = true;
    }
  }

  function openWith(onScreen: ShellScreen, key: string): void {
    initialKey = key.toUpperCase();
    screen = onScreen;
    open = true;
  }

  readonly property bool dryRun: Quickshell.env("QS_POWER_DRYRUN") === "1"

  // key: the letter in the menu. instant: no confirmation needed.
  // tone: "accent", "warn", "orange" or "error"
  readonly property var actions: [
    { id: "lock", key: "L", label: "Lock", verb: "Lock", icon: "lock", instant: true, tone: "accent",
      text: "The screen locks right away. Media keeps playing." },
    { id: "suspend", key: "S", label: "Suspend", verb: "Suspend", icon: "moon", instant: true, tone: "accent",
      text: "Locks first, then sleeps. Wake it with any key." },
    { id: "logout", key: "E", label: "Log out", verb: "Log out", icon: "logout", instant: false, tone: "warn",
      text: "Closes all apps and leaves Hyprland." },
    { id: "restart", key: "R", label: "Restart", verb: "Restart", icon: "restart", instant: false, tone: "orange",
      text: "Closes all apps and restarts the computer." },
    { id: "poweroff", key: "P", label: "Shut down", verb: "Shut down", icon: "power", instant: false, tone: "error",
      text: "Closes all apps and turns the computer off." }
  ]

  function action(id: string): var {
    return actions.find(a => a.id === id) ?? null;
  }

  function run(id: string): void {
    if (dryRun) {
      Quickshell.execDetached(["notify-send", "-a", "Power (dry run)", "Would run: " + id]);
      return;
    }
    switch (id) {
    case "lock": Lock.lock(); break;
    case "suspend": Lock.suspend(); break;
    case "hibernate":
      Lock.lock();
      Quickshell.execDetached(["sh", "-c", "sleep 0.6; systemctl hibernate"]);
      break;
    case "logout": Hypr.exit(); break;
    case "restart": Quickshell.execDetached(["systemctl", "reboot"]); break;
    case "firmware": Quickshell.execDetached(["systemctl", "reboot", "--firmware-setup"]); break;
    case "poweroff": Quickshell.execDetached(["systemctl", "poweroff"]); break;
    }
  }

  // --- Later ------------------------------------------------------------------------
  property string scheduledId: ""
  property double scheduledAt: 0
  readonly property bool scheduled: scheduledId !== ""

  function schedule(id: string, minutes: int): void {
    scheduledId = id;
    scheduledAt = Date.now() + minutes * 60000;
    dueTimer.interval = minutes * 60000;
    dueTimer.restart();
    reminderTimer.interval = Math.max(0, minutes * 60000 - 60000);
    reminderTimer.restart();
  }

  function cancelSchedule(): void {
    if (!scheduled) return;
    const name = action(scheduledId)?.label ?? "";
    dueTimer.stop();
    reminderTimer.stop();
    scheduledId = "";
    Quickshell.execDetached(["notify-send", "-a", "Power", name + " cancelled"]);
  }

  // "14:45"
  readonly property string scheduledTime: scheduled ? Qt.formatDateTime(new Date(scheduledAt), "HH:mm") : ""

  Timer {
    id: dueTimer
    onTriggered: {
      const id = root.scheduledId;
      root.scheduledId = "";
      root.run(id);
    }
  }

  Timer {
    id: reminderTimer
    onTriggered: {
      const name = root.action(root.scheduledId)?.label ?? "";
      Quickshell.execDetached(["notify-send", "-a", "Power", "-u", "critical", name + " in 1 minute",
                               "Open the power menu (Super + Esc) to cancel it."]);
    }
  }

  // --- Header info and what this machine supports ------------------------------------
  property string uptime: ""
  property string system: ""
  // Hibernating needs swap on disk (zram is in memory, it can't hold the image)
  property bool canHibernate: false

  function refreshInfo(): void {
    infoProc.running = true;
  }

  Process {
    id: infoProc
    command: ["sh", "-c",
      "cut -d' ' -f1 /proc/uptime;" +
      ". /etc/os-release 2>/dev/null; echo \"${NAME:-Linux}\";" +
      "swapon --show=NAME --noheadings | grep -v zram | head -1;" +
      "grep -q disk /sys/power/state && echo can-disk"]
    stdout: StdioCollector {
      onStreamFinished: {
        const lines = text.split("\n");
        const seconds = Math.floor(parseFloat(lines[0] ?? "0"));
        const h = Math.floor(seconds / 3600);
        const m = Math.floor(seconds % 3600 / 60);
        root.uptime = "Up " + (h > 0 ? h + " h " : "") + m + " min";
        root.system = (lines[1] ?? "Linux").trim();
        const diskSwap = (lines[2] ?? "").trim() !== "" && lines[2] !== "can-disk";
        root.canHibernate = diskSwap && text.includes("can-disk");
      }
    }
  }
}
