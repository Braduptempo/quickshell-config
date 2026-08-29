//Battery.qml

import QtQuick
import Quickshell.Services.UPower

pragma Singleton

QtObject {
    id: root

    property var battery: UPower.displayDevice
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
