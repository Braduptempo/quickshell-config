//Battery.qml

import QtQuick
import Quickshell.Services.UPower

pragma Singleton

QtObject {
  id: root

  property var battery: UPower.displayDevice

  // Is there a laptop battery at all
  readonly property bool hasBattery: battery !== null && batteries.length > 0

  property bool charging: battery.state === UPowerDeviceState.Charging
  readonly property int batteryLevel: Math.floor(battery.percentage * 100)

  readonly property string timeRemainingStr: {
    let seconds = root.charging ? battery.timeToFull : battery.timeToEmpty;
    if (seconds <= 0) return "Calculating...";

    let hours = Math.floor(seconds / 3600);
    let minutes = Math.floor((seconds % 3600) / 60);

    if (root.charging) {
      return `${hours}h ${minutes}m until full`;
    } else {
      return `${hours}h ${minutes}m remaining`;
    }
  }

  readonly property var allDevices: UPower.devices

  // The laptop's own batteries, each on its own (some laptops have two:
  // an internal one and a removable one). [UPowerDevice], BAT0 first.
  readonly property var batteries: allDevices.values
    .filter(d => d.isLaptopBattery && d.isPresent)
    .sort((a, b) => a.nativePath.localeCompare(b.nativePath))

  // "62%"
  function levelOf(d: var): string {
    return Math.round(d.percentage * 100) + "%";
  }

  readonly property var iconMap: {
    "0": "",
    "25": "",
    "50": "",
    "75": "",
    "100": ""
  }

  property BatteryAnimation animator: BatteryAnimation {
    isCharging: root.charging
    batteryLevel: root.batteryLevel
  }

  readonly property int displayPercentage: root.charging
  ? root.animator.animationFrames[root.animator.animationStep]
  : (batteryLevel <= 1   ? 0  :
    batteryLevel <= 30  ? 25 :
    batteryLevel <= 50  ? 50 :
    batteryLevel <= 90  ? 75 : 100)
}
