// BatteryWarning.qml
// Warns when the laptop battery runs low while not charging: once at
// Config.battery.warnAt, again (critical) at criticalAt. At critical it can
// suspend or hibernate after a minute; plugging in the charger cancels it.
// QS_BATTERY_FAKE=<percent> pretends to be a discharging battery at that level
// (use with QS_POWER_DRYRUN=1 to test the action safely).
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.UPower
import "../config"
import "../widgets/battery"

Singleton {
  id: root

  readonly property string fake: Quickshell.env("QS_BATTERY_FAKE") ?? ""
  readonly property bool active: fake !== "" || Battery.hasBattery
  readonly property int level: fake !== "" ? parseInt(fake) : Battery.batteryLevel
  readonly property bool discharging: fake !== "" || (Battery.battery?.state === UPowerDeviceState.Discharging)

  // 0 fine, 1 low, 2 critical
  readonly property int stage: {
    if (!active || !discharging) return 0;
    if (Config.battery.criticalAt > 0 && level <= Config.battery.criticalAt) return 2;
    if (Config.battery.warnAt > 0 && level <= Config.battery.warnAt) return 1;
    return 0;
  }

  // Highest stage already warned about since the last charge
  property int warned: 0
  property bool actionPending: false

  readonly property string actionVerb: Config.battery.criticalAction === "hibernate" ? "Hibernating" : "Suspending"

  function notify(urgency: string, title: string, body: string): void {
    Quickshell.execDetached(["notify-send", "-a", "Battery", "-u", urgency, "-i", "battery-caution", title, body]);
  }

  function timeLeft(): string {
    if (fake !== "") return "";
    const s = Battery.timeRemainingStr;
    return s.indexOf("Calculating") >= 0 ? "" : " · " + s;
  }

  // Settings and UPower load after start; decide once they're in
  property bool ready: false
  Timer {
    running: true
    interval: 4000
    onTriggered: {
      root.ready = true;
      root.check();
    }
  }

  onStageChanged: check()

  function check(): void {
    if (!ready) return;
    if (stage === 0) {
      // Charging, or back above the warning: warn again next time
      if (!discharging || level > Config.battery.warnAt + 2) warned = 0;
      if (actionPending) {
        actionPending = false;
        actionTimer.stop();
        notify("normal", "Charging", actionVerb + " cancelled");
      }
      return;
    }
    if (stage <= warned) return;
    warned = stage;
    if (stage === 1) {
      notify("normal", "Battery low", level + "% left" + timeLeft() + ". Plug in the charger soon.");
    } else if (Config.battery.criticalAction !== "none") {
      actionPending = true;
      actionTimer.restart();
      notify("critical", "Battery critical: " + level + "%", actionVerb + " in 1 minute unless you plug in the charger.");
    } else {
      notify("critical", "Battery critical: " + level + "%", "Plug in the charger now" + timeLeft() + ".");
    }
  }

  Timer {
    id: actionTimer
    interval: 60 * 1000
    onTriggered: {
      root.actionPending = false;
      if (root.discharging) Power.run(Config.battery.criticalAction);
    }
  }
}
