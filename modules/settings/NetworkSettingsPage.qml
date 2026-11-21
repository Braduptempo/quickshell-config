// NetworkSettingsPage.qml
// Saved Wi-Fi networks, wired and VPN connections (NetworkManager, nmcli) and
// paired Bluetooth devices. Connecting to new networks and pairing happen in
// quick settings; this page manages what's already known.
pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Bluetooth
import Quickshell.Networking
import "../../config"
import "../../components"
import "../../services"
import "../bluetooth"

SettingsPage {
  id: page
  title: "Network & Bluetooth"
  description: "Connecting to a new network or pairing a device happens in quick settings (Super + A)."

  // [{ name, uuid, type, auto, lastUsed, device, active }]
  property var connections: []
  readonly property var wifi: connections.filter(c => c.type === "802-11-wireless")
  readonly property var wired: connections.filter(c => c.type === "802-3-ethernet")
  readonly property var vpns: connections.filter(c => c.type === "vpn" || c.type === "wireguard")
  // Connection waiting for a second click on Forget
  property string confirmForget: ""

  readonly property BluetoothAdapter adapter: Bluetooth.defaultAdapter
  readonly property var devices: Bluetooth.devices.values.filter(d => d.paired || d.bonded || d.connected)

  function refresh(): void {
    list.running = true;
  }

  Component.onCompleted: refresh()

  // While the page is open the computer can be found by other devices, when chosen
  Component.onDestruction: if (adapter && adapter.discoverable) adapter.discoverable = false

  Process {
    id: list
    command: ["nmcli", "-t", "-e", "yes", "-f", "NAME,UUID,TYPE,AUTOCONNECT,TIMESTAMP,DEVICE,ACTIVE", "connection", "show"]
    stdout: StdioCollector {
      onStreamFinished: {
        const rows = [];
        for (const line of text.split("\n")) {
          // Fields are split on ":"; a ":" inside a name comes as "\:"
          const f = line.replace(/\\:/g, "\u0001").split(":").map(s => s.replace(/\u0001/g, ":"));
          if (f.length < 7) continue;
          rows.push({ name: f[0], uuid: f[1], type: f[2], auto: f[3] === "yes", lastUsed: parseInt(f[4]) * 1000, device: f[5], active: f[6] === "yes" });
        }
        page.connections = rows.sort((a, b) => b.lastUsed - a.lastUsed);
      }
    }
  }

  function nm(args: var): void {
    run.command = ["nmcli"].concat(args);
    run.running = true;
  }

  Process {
    id: run
    onExited: page.refresh()
  }

  // "today", "2 weeks ago", "in March"
  function lastUsed(ms: real): string {
    if (!ms) return "never used";
    const days = Math.floor((Date.now() - ms) / 86400000);
    if (days < 1) return "last used today";
    if (days < 2) return "last used yesterday";
    if (days < 14) return "last used " + days + " days ago";
    if (days < 60) return "last used " + Math.floor(days / 7) + " weeks ago";
    return "last used in " + Qt.formatDate(new Date(ms), "MMMM yyyy");
  }

  // --- One saved connection -------------------------------------------------------------
  component ConnectionRow: RowLayout {
    id: row
    property var connection
    property bool showAuto: true
    property bool canToggle: false
    readonly property bool confirming: page.confirmForget === connection.uuid

    Layout.fillWidth: true
    implicitHeight: 44
    spacing: 10

    ColumnLayout {
      Layout.fillWidth: true
      spacing: 1
      Label { text: row.connection.name; font.weight: row.connection.active ? Font.Bold : Font.Normal; elide: Text.ElideRight; Layout.fillWidth: true }
      Label {
        text: (row.connection.active ? "In use" + (row.connection.device ? " · " + row.connection.device : "") : page.lastUsed(row.connection.lastUsed))
        kind: "muted"
        color: row.connection.active ? Theme.good : Theme.subtext
        font.pixelSize: Theme.font.label
      }
    }

    Button {
      visible: row.canToggle
      text: row.connection.active ? "Disconnect" : "Connect"
      variant: "ghost"
      size: Theme.size.buttonRow
      onClicked: page.nm(["connection", row.connection.active ? "down" : "up", "uuid", row.connection.uuid])
    }

    Label { visible: row.showAuto; text: "Auto"; kind: "muted"; font.pixelSize: Theme.font.label }
    Toggle {
      visible: row.showAuto
      checked: row.connection.auto
      accessibleName: "Connect to " + row.connection.name + " automatically"
      onToggled: value => page.nm(["connection", "modify", "uuid", row.connection.uuid, "connection.autoconnect", value ? "yes" : "no"])
    }

    Button {
      text: row.confirming ? "Click again" : "Forget"
      variant: "dangerSoft"
      size: Theme.size.buttonRow
      onClicked: {
        if (row.confirming) {
          page.confirmForget = "";
          page.nm(["connection", "delete", "uuid", row.connection.uuid]);
        } else {
          page.confirmForget = row.connection.uuid;
          forgetReset.restart();
        }
      }
    }
  }

  Timer {
    id: forgetReset
    interval: 4000
    onTriggered: page.confirmForget = ""
  }

  component Section: Rectangle {
    id: section
    property string heading
    property bool showSwitch: false
    property bool switchOn: false
    signal switched(bool on)
    default property alias rows: sectionColumn.data

    Layout.fillWidth: true
    implicitHeight: sectionColumn.implicitHeight + 24
    radius: Theme.radiusCard
    color: Theme.item

    ColumnLayout {
      id: sectionColumn
      x: 14
      y: 12
      width: parent.width - 28
      spacing: 2

      RowLayout {
        Layout.fillWidth: true
        Layout.bottomMargin: 4
        Label { text: section.heading; kind: "label"; Layout.fillWidth: true }
        Toggle {
          visible: section.showSwitch
          checked: section.switchOn
          accessibleName: section.heading
          onToggled: value => section.switched(value)
        }
      }
    }
  }

  // --- Wi-Fi -------------------------------------------------------------------------------
  Section {
    heading: "Wi-Fi · saved networks"
    showSwitch: true
    switchOn: Networking.wifiEnabled
    onSwitched: on => Networking.wifiEnabled = on

    Label { visible: page.wifi.length === 0; text: "No saved Wi-Fi networks"; kind: "muted" }
    Repeater {
      model: page.wifi
      ConnectionRow { required property var modelData; connection: modelData }
    }
  }

  // --- Ethernet ------------------------------------------------------------------------------
  Section {
    visible: page.wired.length > 0
    heading: "Ethernet"
    Repeater {
      model: page.wired
      ConnectionRow { required property var modelData; connection: modelData; canToggle: true }
    }
  }

  // --- VPN -------------------------------------------------------------------------------------
  Section {
    heading: "VPN"
    Label { visible: page.vpns.length === 0; text: "No VPNs. Import one with nmcli (e.g. a WireGuard .conf) and it shows up here."; kind: "muted"; wrapMode: Text.Wrap; Layout.fillWidth: true }
    Repeater {
      model: page.vpns
      ConnectionRow { required property var modelData; connection: modelData; canToggle: true; showAuto: false }
    }
  }

  // --- Bluetooth ---------------------------------------------------------------------------------
  Section {
    heading: "Bluetooth · devices"
    showSwitch: !BluetoothCheck.missing
    switchOn: page.adapter?.enabled ?? false
    onSwitched: on => { if (page.adapter) page.adapter.enabled = on; }

    BluetoothHint { Layout.fillWidth: true }

    Label {
      visible: !BluetoothCheck.missing && page.devices.length === 0
      text: "No paired devices. Pair one in quick settings (Super + A → Bluetooth)."
      kind: "muted"
      wrapMode: Text.Wrap
      Layout.fillWidth: true
    }

    Repeater {
      model: page.devices

      RowLayout {
        id: btRow
        required property BluetoothDevice modelData
        readonly property bool confirming: page.confirmForget === modelData.address
        Layout.fillWidth: true
        implicitHeight: 44
        spacing: 10

        Icon { name: "bluetooth"; size: 15; color: btRow.modelData.connected ? Theme.accent : Theme.subtext }
        ColumnLayout {
          Layout.fillWidth: true
          spacing: 1
          Label { text: btRow.modelData.name || btRow.modelData.deviceName || btRow.modelData.address; font.weight: btRow.modelData.connected ? Font.Bold : Font.Normal; elide: Text.ElideRight; Layout.fillWidth: true }
          Label {
            text: (btRow.modelData.connected ? "Connected" : "Not connected") + (btRow.modelData.batteryAvailable ? " · battery " + Math.round(btRow.modelData.battery * 100) + "%" : "")
            kind: "muted"
            color: btRow.modelData.connected ? Theme.good : Theme.subtext
            font.pixelSize: Theme.font.label
          }
        }
        Button {
          text: btRow.modelData.connected ? "Disconnect" : "Connect"
          variant: "ghost"
          size: Theme.size.buttonRow
          onClicked: btRow.modelData.connected ? btRow.modelData.disconnect() : btRow.modelData.connect()
        }
        Button {
          text: btRow.confirming ? "Click again" : "Forget"
          variant: "dangerSoft"
          size: Theme.size.buttonRow
          onClicked: {
            if (btRow.confirming) {
              page.confirmForget = "";
              btRow.modelData.forget();
            } else {
              page.confirmForget = btRow.modelData.address;
              forgetReset.restart();
            }
          }
        }
      }
    }
  }

  SettingRow {
    visible: page.adapter !== null
    title: "Visible to other devices"
    subtitle: "Only while this page is open, so a phone or another computer can find this one."
    Toggle {
      checked: page.adapter?.discoverable ?? false
      accessibleName: "Visible to other devices"
      onToggled: value => { if (page.adapter) page.adapter.discoverable = value; }
    }
  }
}
