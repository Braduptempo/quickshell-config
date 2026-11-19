// Time.qml
pragma Singleton

import QtQuick
import Quickshell

Singleton {
    id: root

    // Formatted in QML instead of running `date` every second.
    // `date` printed a trailing newline, which pushed the clock onto two lines.
    readonly property string time: Qt.formatDateTime(clock.date, "HH:mm")

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }
}
