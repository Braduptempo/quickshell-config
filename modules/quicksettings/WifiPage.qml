// WifiPage.qml
// Wi-Fi details: toggle, current connection and nearby networks.
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
    title: root.network.wifiDevices.length > 0 ? "Wi-Fi" : "Network"
    showToggle: root.network.wifiDevices.length > 0
    checked: Networking.wifiEnabled
    onToggled: value => Networking.wifiEnabled = value
  }

  Label {
    visible: root.network.isWiredConnected
    text: "Ethernet is connected and used first"
    kind: "muted"
    Layout.fillWidth: true
  }

  ConnectionStats {
    Layout.fillWidth: true
  }

  Label {
    visible: root.network.wifiDevices.length > 0 && !Networking.wifiEnabled
    text: "Wi-Fi is off"
    kind: "muted"
    horizontalAlignment: Text.AlignHCenter
    Layout.fillWidth: true
    Layout.topMargin: 8
    Layout.bottomMargin: 8
  }

  Card {
    visible: Networking.wifiEnabled && root.sorted.length > 0
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
            subtitle: entry.modelData.connected ? "Connected"
                    : entry.modelData.stateChanging ? "Connecting…"
                    : entry.modelData.connectionFailed ? "Couldn't connect"
                    : entry.modelData.known ? "Saved" : entry.secured ? "Secured" : "Open"
            subtitleColor: entry.modelData.connected ? Theme.good
                         : entry.modelData.connectionFailed ? Theme.error : Theme.subtext

            Icon {
              name: "wifi"
              size: 16
              color: entry.modelData.connected ? Theme.good : Theme.text
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
