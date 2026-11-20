// ConnectionStats.qml
// IP, gateway, speeds and ping of the active connection, from
// scripts/netstats.sh. Polls every 2 s only while it is visible.
pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../../config"
import "../../components"

Card {
  id: root

  property var stats: ({ connected: false })
  property real lastRx: 0
  property real lastTx: 0
  property real down: 0
  property real up: 0

  visible: stats.connected === true
  implicitHeight: grid.implicitHeight + 20

  function speed(bytesPerSecond: real): string {
    if (!bytesPerSecond || bytesPerSecond <= 0) return "0.0 Mbit/s";
    return (bytesPerSecond * 8 / 1000000).toFixed(1) + " Mbit/s";
  }

  Timer {
    interval: 2000
    running: root.QsWindow.window?.visible ?? false
    repeat: true
    triggeredOnStart: true
    onTriggered: proc.running = true
  }

  Process {
    id: proc
    command: ["bash", Quickshell.shellPath("scripts/netstats.sh")]
    stdout: SplitParser {
      onRead: data => {
        let json;
        try {
          json = JSON.parse(data);
        } catch (e) {
          return;
        }
        if (json.connected) {
          if (root.lastRx > 0) {
            root.down = (json.rx - root.lastRx) / 2;
            root.up = (json.tx - root.lastTx) / 2;
          }
          root.lastRx = json.rx;
          root.lastTx = json.tx;
        }
        root.stats = json;
      }
    }
  }

  GridLayout {
    id: grid
    x: 12
    y: 10
    width: parent.width - 24
    columns: 4
    columnSpacing: 10
    rowSpacing: 6

    Label { text: "IP"; kind: "muted" }
    Label { text: root.stats.ip ?? "–"; font.weight: Font.Bold; Layout.fillWidth: true }
    Label { text: "Down"; kind: "muted" }
    Label { text: root.speed(root.down); color: Theme.good; font.weight: Font.Bold; Layout.fillWidth: true }

    Label { text: "Gateway"; kind: "muted" }
    Label { text: root.stats.gw ?? "–"; Layout.fillWidth: true }
    Label { text: "Up"; kind: "muted" }
    Label { text: root.speed(root.up); color: Theme.accent; font.weight: Font.Bold; Layout.fillWidth: true }

    Label { text: "Ping"; kind: "muted" }
    Label {
      text: (root.stats.ping ?? 0) + " ms" + ((root.stats.loss ?? 0) > 0 ? " · " + root.stats.loss + "% loss" : "")
      color: (root.stats.loss ?? 0) > 0 ? Theme.error : (root.stats.ping ?? 0) > 50 ? Theme.warn : Theme.text
      Layout.columnSpan: 3
    }
  }
}
