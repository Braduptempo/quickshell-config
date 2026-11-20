// MainPage.qml
// The first page: toggles, sliders and (where available) the power profile.
pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Bluetooth
import Quickshell.Networking
import "../../config"
import "../../components"
import "../../services"
import "../../widgets/sound"
import "../../widgets/battery"


ColumnLayout {
  id: root

  required property var network
  readonly property BluetoothAdapter adapter: Bluetooth.defaultAdapter
  readonly property var btConnected: Bluetooth.devices.values.filter(d => d.connected)

  spacing: 12

  // --- Header: battery (laptop only) ---------------------------------------
  RowLayout {
    visible: Battery.hasBattery
    Layout.fillWidth: true

    Rectangle {
      implicitHeight: 34
      implicitWidth: batteryRow.implicitWidth + 24
      radius: 17
      color: Theme.item

      Row {
        id: batteryRow
        anchors.centerIn: parent
        spacing: 8
        Icon { name: "battery"; size: 16; color: Battery.charging ? Theme.good : Theme.text; anchors.verticalCenter: parent.verticalCenter }
        Label { text: Battery.batteryLevel + "%"; font.weight: Font.Bold; anchors.verticalCenter: parent.verticalCenter }
        Label { text: Battery.timeRemainingStr; kind: "muted"; anchors.verticalCenter: parent.verticalCenter }
      }
    }
  }

  // --- Toggles ---------------------------------------------------------------
  GridLayout {
    Layout.fillWidth: true
    columns: 2
    columnSpacing: 8
    rowSpacing: 8

    // Ethernet first when the machine has a port; it carries the traffic
    // whenever a cable is in (lowest route metric)
    Tile {
      Layout.fillWidth: true
      visible: root.network.hasWiredDevice
      icon: "ethernet"
      label: "Ethernet"
      status: root.network.isWiredConnected ? "Connected" : "Unplugged"
      statusColor: root.network.isWiredConnected ? Theme.subtext : Theme.warn
      checked: root.network.primary === "ethernet"
      hasDetails: true
      onToggled: Panels.quickSettingsPage = "network"
      onDetailsRequested: Panels.quickSettingsPage = "network"
    }

    Tile {
      Layout.fillWidth: true
      visible: root.network.hasWifiDevice
      readonly property bool inStandby: Networking.wifiEnabled && root.network.activeNetwork !== null && root.network.primary !== "wifi"
      icon: Networking.wifiEnabled ? "wifi" : "wifi-off"
      label: "Wi-Fi"
      status: !Networking.wifiEnabled ? "Off"
            : !root.network.activeNetwork ? "Not connected"
            : root.network.activeNetwork.name + (inStandby ? " · standby" : "")
      checked: Networking.wifiEnabled
      standby: inStandby
      hasDetails: true
      onToggled: Networking.wifiEnabled = !Networking.wifiEnabled
      onDetailsRequested: Panels.quickSettingsPage = "network"
    }

    Tile {
      Layout.fillWidth: true
      visible: root.adapter !== null
      icon: "bluetooth"
      label: "Bluetooth"
      status: !root.adapter?.enabled ? "Off"
            : root.btConnected.length === 1 ? root.btConnected[0].name
            : root.btConnected.length > 1 ? root.btConnected.length + " devices" : "On"
      checked: root.adapter?.enabled ?? false
      hasDetails: true
      onToggled: if (root.adapter) root.adapter.enabled = !root.adapter.enabled
      onDetailsRequested: Panels.quickSettingsPage = "bluetooth"
    }

    Tile {
      Layout.fillWidth: true
      icon: "moon"
      label: "Do not disturb"
      status: Notifications.dnd ? "On" : "Off"
      checked: Notifications.dnd
      onToggled: Notifications.dnd = !Notifications.dnd
    }

    Tile {
      Layout.fillWidth: true
      visible: Session.nightLightAvailable
      icon: "sun"
      label: "Night light"
      status: Session.nightLight ? Session.nightLightTemperature + " K" : "Off"
      checked: Session.nightLight
      onToggled: Session.nightLight = !Session.nightLight
    }

    Tile {
      Layout.fillWidth: true
      icon: "activity"
      label: "Caffeine"
      status: Session.caffeine ? "Screen stays on" : "Off"
      checked: Session.caffeine
      onToggled: Session.caffeine = !Session.caffeine
    }

    Tile {
      Layout.fillWidth: true
      icon: Sound.isMicMuted ? "mic-off" : "mic"
      label: "Microphone"
      status: Sound.isMicMuted ? "Muted" : "On"
      checked: !Sound.isMicMuted
      onToggled: Sound.toggleMicMute()
    }
  }

  // --- Sliders ---------------------------------------------------------------
  RowLayout {
    Layout.fillWidth: true
    spacing: 6

    PillSlider {
      Layout.fillWidth: true
      icon: Sound.isMuted ? "volume-off" : "volume"
      label: "Volume"
      value: Sound.volume / 100
      onMoved: v => Sound.setVolume(v)
    }

    IconButton {
      icon: "chevron-right"
      size: Theme.size.slider
      accessibleName: "Sound output and apps"
      onClicked: Panels.quickSettingsPage = "audio"
    }
  }

  PillSlider {
    Layout.fillWidth: true
    visible: Session.brightnessAvailable
    icon: "sun"
    label: "Brightness"
    fillColor: Theme.warn
    value: Session.brightness
    onMoved: v => Session.setBrightness(v)
  }

  // --- Power profile -----------------------------------------------------------
  Segmented {
    Layout.fillWidth: true
    visible: Session.profilesAvailable
    accessibleName: "Power profile"
    model: ["Saver", "Balanced", "Performance"]
    readonly property var values: ["power-saver", "balanced", "performance"]
    currentIndex: Math.max(0, values.indexOf(Session.profile))
    onActivated: index => Session.setProfile(values[index])
  }
}
