// NetworkPage.qml
// Network details: the connection in use (with IP, speeds and ping),
// Ethernet when it is unplugged, and Wi-Fi with its networks.
// Known networks connect with one click; new secured ones ask for a password.
pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Networking
import "../../config"
import "../../components"

ColumnLayout {
  id: root

  required property var network
  property string expandedName: ""

  readonly property var sorted: {
    const list = (root.network.availableNetworks ?? []).filter(n => n.name !== "");
    return list.slice().sort((a, b) => {
      if (a.connected !== b.connected) return a.connected ? -1 : 1;
      if (a.known !== b.known) return a.known ? -1 : 1;
      return (b.signalStrength ?? 0) - (a.signalStrength ?? 0);
    });
  }

  spacing: 12

  PageHeader {
    Layout.fillWidth: true
    title: "Network"
  }

  // --- In use: whichever connection carries the traffic ---------------------
  Label {
    visible: stats.visible
    text: "In use"
    kind: "label"
  }

  ConnectionStats {
    id: stats
    network: root.network
    Layout.fillWidth: true
  }

  Label {
    visible: root.network.primary === "none"
    text: "No connection. IP, speed and ping show up here as soon as a cable or Wi-Fi is connected."
    kind: "muted"
    wrapMode: Text.WordWrap
    Layout.fillWidth: true
  }

  // --- Ethernet, only when it's not the one in use ---------------------------
  Label {
    visible: root.network.hasWiredDevice && root.network.primary !== "ethernet"
    text: "Ethernet"
    kind: "label"
  }

  Card {
    visible: root.network.hasWiredDevice && root.network.primary !== "ethernet"
    Layout.fillWidth: true
    implicitHeight: wiredRow.implicitHeight

    ListRow {
      id: wiredRow
      width: parent.width
      first: true
      title: root.network.wiredName
      subtitle: root.network.isWiredConnected ? "Connected" : "Plug in a cable to use it"

      Icon {
        name: "ethernet"
        size: 16
        color: Theme.subtext
        anchors.verticalCenter: parent.verticalCenter
      }

      Chip {
        text: root.network.isWiredConnected ? "Connected" : "Unplugged"
        tone: root.network.isWiredConnected ? "neutral" : "warn"
        anchors.verticalCenter: parent.verticalCenter
      }
    }
  }

  // --- Wi-Fi ---------------------------------------------------------------------
  RowLayout {
    visible: root.network.hasWifiDevice
    Layout.fillWidth: true
    Layout.topMargin: 4

    Label {
      text: "Wi-Fi"
      kind: "label"
      Layout.fillWidth: true
    }

    Toggle {
      checked: Networking.wifiEnabled
      accessibleName: "Wi-Fi"
      onToggled: value => Networking.wifiEnabled = value
    }
  }

  Label {
    visible: root.network.hasWifiDevice && Networking.wifiEnabled && root.network.activeNetwork !== null && root.network.primary !== "wifi"
    text: "Standby: Wi-Fi stays connected and takes over when the cable is unplugged."
    kind: "muted"
    wrapMode: Text.WordWrap
    Layout.fillWidth: true
  }

  Label {
    visible: root.network.hasWifiDevice && !Networking.wifiEnabled
    text: "Wi-Fi is off"
    kind: "muted"
    Layout.fillWidth: true
  }

  Card {
    visible: root.network.hasWifiDevice && Networking.wifiEnabled && root.sorted.length > 0
    Layout.fillWidth: true
    implicitHeight: list.implicitHeight

    Column {
      id: list
      width: parent.width

      Repeater {
        model: root.sorted.slice(0, 8)

        Column {
          id: entry
          required property var modelData
          required property int index
          readonly property bool expanded: root.expandedName === modelData.name
          readonly property bool secured: modelData.security !== undefined && modelData.security !== WifiSecurityType.Open

          width: list.width

          ListRow {
            width: parent.width
            first: entry.index === 0
            title: entry.modelData.name
            subtitle: entry.modelData.connected ? (root.network.primary === "wifi" ? "Connected · in use" : "Connected · standby")
                    : entry.modelData.stateChanging ? "Connecting…"
                    : entry.modelData.connectionFailed ? "Couldn't connect"
                    : entry.modelData.known ? "Saved" : entry.secured ? "Secured" : "Open"
            // A connected network never shows red, even if an older attempt failed
            subtitleColor: entry.modelData.connected ? (root.network.primary === "wifi" ? Theme.good : Theme.subtext)
                         : entry.modelData.connectionFailed ? Theme.error : Theme.subtext

            Icon {
              name: "wifi"
              size: 16
              color: entry.modelData.connected && root.network.primary === "wifi" ? Theme.good : Theme.text
              opacity: 0.4 + 0.6 * (entry.modelData.signalStrength ?? 0)
              anchors.verticalCenter: parent.verticalCenter
            }

            Button {
              size: Theme.size.buttonRow
              variant: entry.modelData.connected ? "ghost" : "secondary"
              text: entry.modelData.connected ? "Disconnect" : "Connect"
              onClicked: {
                const n = entry.modelData;
                if (n.connected) {
                  n.disconnect();
                } else if (n.known || !entry.secured) {
                  n.connect();
                } else {
                  root.expandedName = entry.expanded ? "" : n.name;
                }
              }
            }
          }

          RowLayout {
            visible: entry.expanded
            width: parent.width - 20
            x: 10
            height: visible ? implicitHeight + 10 : 0
            spacing: 6

            TextField {
              id: password
              Layout.fillWidth: true
              placeholder: "Password"
              password: true
              onAccepted: connectButton.clicked()
            }

            Button {
              id: connectButton
              text: "Join"
              variant: "primary"
              onClicked: {
                entry.modelData.connectWithPsk(password.text);
                password.text = "";
                root.expandedName = "";
              }
            }
          }
        }
      }
    }
  }
}
