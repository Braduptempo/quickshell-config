// StatusPill.qml
// Network, Bluetooth, volume and battery in one pill. Click opens quick
// settings on this monitor. Scroll: volume ±5%. Middle click: mute.
import QtQuick
import Quickshell
import Quickshell.Bluetooth
import "../../config"
import "../../components"
import "../../services"
import "../../widgets/network"
import "../../widgets/sound"
import "../../widgets/battery"

BarItem {
  id: root

  required property ShellScreen screen

  padding: 12
  active: Panels.quickSettingsOpen && Panels.screen === screen
  accessibleName: "Quick settings. " + networkText + ", volume " + Sound.volume + " percent" + (Battery.hasBattery ? ", battery " + Battery.batteryLevel + " percent" : "")

  readonly property string networkText: network.isWiredConnected ? "Ethernet"
                                       : network.activeNetwork ? "Wi-Fi " + network.activeNetwork.name
                                       : "offline"
  readonly property BluetoothAdapter adapter: Bluetooth.defaultAdapter
  readonly property int btConnected: Bluetooth.devices.values.filter(d => d.connected).length

  onClicked: mouse => {
    if (mouse.button === Qt.MiddleButton) Sound.toggleMute();
    else Panels.toggleQuickSettings(root.screen);
  }
  onScrolled: wheel => Sound.setVolume(Sound.volume / 100 + (wheel.angleDelta.y > 0 ? 0.05 : -0.05))

  NetworkManager {
    id: network
  }

  Icon {
    name: network.isWiredConnected ? "ethernet" : network.activeNetwork ? "wifi" : "wifi-off"
    size: 15
    color: network.isWiredConnected || network.activeNetwork ? Theme.text : Theme.subtext
    anchors.verticalCenter: parent.verticalCenter
  }

  Icon {
    visible: root.adapter !== null && root.adapter.enabled
    name: "bluetooth"
    size: 15
    color: root.btConnected > 0 ? Theme.accent : Theme.text
    anchors.verticalCenter: parent.verticalCenter
  }

  Icon {
    name: Sound.isMuted ? "volume-off" : Sound.volume > 60 ? "volume-high" : "volume"
    size: 15
    color: Sound.isMuted ? Theme.subtext : Theme.text
    anchors.verticalCenter: parent.verticalCenter
  }

  Icon {
    visible: Sound.isMicMuted
    name: "mic-off"
    size: 15
    color: Theme.error
    anchors.verticalCenter: parent.verticalCenter
  }

  Icon {
    visible: Battery.hasBattery
    name: "battery"
    size: 15
    color: Battery.charging ? Theme.good : Battery.batteryLevel <= 15 ? Theme.error : Theme.text
    anchors.verticalCenter: parent.verticalCenter
  }
}
