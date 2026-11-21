// ConnectionStats.qml
// The connection in use (Ethernet or Wi-Fi) with IP, gateway, speeds and
// ping from scripts/netstats.sh. Polls every 2 s only while it is visible.
pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../../config"
import "../../components"

Card {
  id: root

  required property var network
  readonly property bool wired: network.primary === "ethernet"
  property var stats: ({ connected: false })
  property real lastRx: 0
  property real lastTx: 0
  property real down: 0
  property real up: 0

  visible: stats.connected === true && network.primary !== "none"
  implicitHeight: header.implicitHeight + grid.implicitHeight + 20

  function linkSpeed(mbit: real): string {
    if (!mbit || mbit <= 0) return "";
    return mbit >= 1000 ? (mbit / 1000) + " Gbit/s" : mbit + " Mbit/s";
  }

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

  ListRow {
    id: header
    width: parent.width
    first: true
    title: root.wired ? "Ethernet · " + (root.stats.iface ?? root.network.wiredName)
                      : "Wi-Fi · " + (root.network.activeNetwork?.name ?? "")
    subtitle: root.wired ? root.linkSpeed(root.stats.speed ?? 0)
            : "Signal " + ((root.stats.all_signals ?? {})[root.network.activeNetwork?.name ?? ""] ?? "–") + "%"

    Icon {
      name: root.wired ? "ethernet" : "wifi"
      size: 16
      color: Theme.good
      anchors.verticalCenter: parent.verticalCenter
    }

    Chip {
      text: "In use"
      tone: "good"
      anchors.verticalCenter: parent.verticalCenter
    }
  }

  Rectangle {
    y: header.height
    width: parent.width
    height: 1
    color: Theme.hairline
  }

  GridLayout {
    id: grid
    x: 12
    y: header.height + 10
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
