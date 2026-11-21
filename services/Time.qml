// Time.qml
// The clock for the whole shell: one SystemClock, ticking per minute.
pragma Singleton

import QtQuick
import Quickshell

Singleton {
  id: root

  readonly property date date: clock.date
  readonly property string time: Qt.formatDateTime(clock.date, "HH:mm")

  SystemClock {
    id: clock
    precision: SystemClock.Minutes
  }
}
