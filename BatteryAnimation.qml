// BatteryAnimation.qml
import QtQuick

QtObject {
    id: root
    
    // The current index position pointing to the active frame in animationFrames
    property int animationStep: 0
    
    // The explicit percentage brackets matching the keys in your Battery iconMap
    readonly property var animationFrames: [0, 25, 50, 75, 100]

    // Inputs: Expects live state values bound from your system battery service (e.g., UPower)
    property bool isCharging: false
    property int batteryLevel: 0

    // The dynamically calculated lower boundary (floor index) of the charging animation loop
    property int startStep

    // Reactive evaluation: Automatically computes the animation's starting floor 
    // whenever 'isCharging' or 'batteryLevel' updates.
    startStep: {
        if (!isCharging) return 0;
        if (batteryLevel <= 15) return 0; // Loop: 0% -> 25% -> 50% -> 75% -> 100% -> 0%...
        if (batteryLevel <= 40) return 1; // Loop: 25% -> 50% -> 75% -> 100% -> 25%...
        if (batteryLevel <= 65) return 2; // Loop: 50% -> 75% -> 100% -> 50%...
        if (batteryLevel <= 94) return 3; // Loop: 75% -> 100% -> 75%...
        return 4;                         // Static Full (95%+): Stays pinned at 100%
    }
    
    // Instant Feedback: Snaps the animation frame forward the exact millisecond 
    // the charger is connected, bypassing the typical 1-second timer delay.
    onIsChargingChanged: {
        if (isCharging) {
            root.animationStep = root.startStep;
        } else {
            root.animationStep = 0; // Reset index back to 0 when discharging
        }
    }

    // Safety Guard: If the physical battery capacity tier increases while charging,
    // this ensures the animation step scales upward and never drops below the new floor.
    onStartStepChanged: {
        if (isCharging && root.animationStep < root.startStep) {
            root.animationStep = root.startStep;
        }
    }

    // The master timing clock responsible for incremental animation cycling
    property Timer animationTimer: Timer {
        id: animationTimer
        interval: 1000
        repeat: true
        running: root.isCharging // Automatically ticks only while the charger is active
        
        onTriggered: {
            // Increment the pointer step by 1 frame
            root.animationStep++;
            
            // Loop Controller: If the animation extends past the 100% frame boundary (index 4),
            // jump cleanly back to 'startStep' instead of dropping back down to an empty battery layout (0).
            if (root.animationStep >= root.animationFrames.length) {
                root.animationStep = root.startStep;
            }
        }
    }
}