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

Rectangle {
  id: root

  required property var network
  readonly property bool wired: network.primary === "ethernet"
  property var stats: ({ connected: false })
  property real lastRx: 0
  property real lastTx: 0
  property real down: 0
  property real up: 0

  visible: stats.connected === true && network.primary !== "none"
  implicitHeight: content.implicitHeight + 24
  radius: Theme.radiusCard
  color: Theme.alpha(Theme.accent, 0.08)
  border.width: 1
  border.color: Theme.alpha(Theme.accent, 0.3)

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

  // One of the three numbers: a label over a value
  component Stat: Rectangle {
    id: stat
    property string label
    property string value
    property color valueColor: Theme.text
    Layout.fillWidth: true
    Layout.preferredWidth: 1
    implicitHeight: statColumn.implicitHeight + 14
    radius: Theme.r(10)
    color: Theme.item
    Column {
      id: statColumn
      x: 10
      anchors.verticalCenter: parent.verticalCenter
      spacing: 1
      Label { text: stat.label; kind: "muted"; font.pixelSize: Theme.font.label }
      Label { text: stat.value; color: stat.valueColor; font.weight: Font.Bold; font.pixelSize: Theme.font.small }
    }
  }

  ColumnLayout {
    id: content
    x: 12
    y: 12
    width: parent.width - 24
    spacing: 10

    // The connection: icon, name, and how it's connected
    RowLayout {
      Layout.fillWidth: true
      spacing: 10
      Rectangle {
        implicitWidth: 32
        implicitHeight: 32
        radius: Theme.pill(height)
        color: Theme.accent
        Icon { anchors.centerIn: parent; name: root.wired ? "ethernet" : "wifi"; size: 16; color: Theme.onAccent }
      }
      ColumnLayout {
        Layout.fillWidth: true
        spacing: 1
        Label {
          Layout.fillWidth: true
          text: root.wired ? "Ethernet" : (root.network.activeNetwork?.name ?? "Wi-Fi")
          font.weight: Font.Bold
          elide: Text.ElideRight
        }
        Label {
          Layout.fillWidth: true
          text: ["Connected · in use",
                 root.wired ? (root.stats.iface ?? root.network.wiredName) : "",
                 root.wired ? root.linkSpeed(root.stats.speed ?? 0)
                            : "signal " + ((root.stats.all_signals ?? {})[root.network.activeNetwork?.name ?? ""] ?? "–") + "%"]
                .filter(t => t !== "").join(" · ")
          color: Theme.good
          font.pixelSize: Theme.font.label
          elide: Text.ElideRight
        }
      }
    }

    RowLayout {
      Layout.fillWidth: true
      spacing: 6
      Stat { label: "Download"; value: root.speed(root.down); valueColor: Theme.good }
      Stat { label: "Upload"; value: root.speed(root.up); valueColor: Theme.accent }
      Stat {
        label: "Ping"
        value: (root.stats.ping ?? 0) + " ms" + ((root.stats.loss ?? 0) > 0 ? " · " + root.stats.loss + "% loss" : "")
        valueColor: (root.stats.loss ?? 0) > 0 ? Theme.error : (root.stats.ping ?? 0) > 50 ? Theme.warn : Theme.text
      }
    }

    Label {
      Layout.fillWidth: true
      text: "IP " + (root.stats.ip ?? "–") + " · Gateway " + (root.stats.gw ?? "–")
      kind: "muted"
      font.pixelSize: Theme.font.label
      elide: Text.ElideRight
    }
  }
}
