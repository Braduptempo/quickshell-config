// BluetoothPage.qml
// Bluetooth details: toggle, scan, and devices with connect / pair.
pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Bluetooth
import "../../config"
import "../../components"

ColumnLayout {
  id: root

  readonly property BluetoothAdapter adapter: Bluetooth.defaultAdapter
  readonly property var devices: {
    const list = (adapter?.devices.values ?? []).filter(d => d.name !== "" || d.paired);
    return list.slice().sort((a, b) => {
      if (a.connected !== b.connected) return a.connected ? -1 : 1;
      if (a.paired !== b.paired) return a.paired ? -1 : 1;
      return a.name.localeCompare(b.name);
    });
  }

  function iconFor(device: BluetoothDevice): string {
    const icon = device.icon ?? "";
    if (icon.indexOf("audio") >= 0 || icon.indexOf("headset") >= 0 || icon.indexOf("headphone") >= 0) return "headphones";
    if (icon.indexOf("phone") >= 0) return "monitor";
    if (icon.indexOf("keyboard") >= 0) return "keyboard";
    return "bluetooth";
  }

  // Stop scanning when the page closes
  Component.onDestruction: if (adapter && adapter.discovering) adapter.discovering = false

  spacing: 12

  PageHeader {
    Layout.fillWidth: true
    title: "Bluetooth"
    showToggle: root.adapter !== null
    checked: root.adapter?.enabled ?? false
    onToggled: value => { if (root.adapter) root.adapter.enabled = value; }

    Button {
      visible: root.adapter?.enabled ?? false
      size: Theme.size.buttonList
      variant: root.adapter?.discovering ? "outline" : "ghost"
      text: root.adapter?.discovering ? "Scanning…" : "Scan"
      onClicked: root.adapter.discovering = !root.adapter.discovering
    }
  }

  Label {
    visible: root.adapter === null || !root.adapter.enabled
    text: root.adapter === null ? "No Bluetooth adapter found" : "Bluetooth is off"
    kind: "muted"
    horizontalAlignment: Text.AlignHCenter
    Layout.fillWidth: true
    Layout.topMargin: 8
    Layout.bottomMargin: 8
  }

  Card {
    visible: (root.adapter?.enabled ?? false) && root.devices.length > 0
    Layout.fillWidth: true
    implicitHeight: list.implicitHeight

    Column {
      id: list
      width: parent.width

      Repeater {
        model: root.devices.slice(0, 8)

        ListRow {
          id: row
          required property BluetoothDevice modelData
          required property int index

          width: list.width
          first: index === 0
          title: modelData.name
          subtitle: modelData.connected ? "Connected" + (modelData.batteryAvailable ? " · battery " + Math.round(modelData.battery * 100) + "%" : "")
                  : modelData.pairing ? "Pairing…"
                  : modelData.paired ? "Paired" : "Available"
          subtitleColor: modelData.connected ? Theme.good : Theme.subtext

          Icon {
            name: root.iconFor(row.modelData)
            size: 16
            color: row.modelData.connected ? Theme.accent : Theme.text
            anchors.verticalCenter: parent.verticalCenter
          }

          Button {
            size: Theme.size.buttonRow
            variant: row.modelData.connected ? "ghost" : "secondary"
            text: row.modelData.connected ? "Disconnect" : row.modelData.paired ? "Connect" : "Pair"
            onClicked: {
              const d = row.modelData;
              if (d.connected) d.disconnect();
              else if (d.paired) d.connect();
              else d.pair();
            }
          }
        }
      }
    }
  }

  Label {
    visible: (root.adapter?.enabled ?? false) && root.devices.length === 0
    text: "No devices yet. Press Scan and put your device in pairing mode."
    kind: "muted"
    wrapMode: Text.WordWrap
    Layout.fillWidth: true
  }
}
