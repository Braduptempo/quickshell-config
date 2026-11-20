// StatusPill.qml
// Network, Bluetooth, volume and battery in one pill. Until the quick
// settings panel exists, each icon opens its existing dropdown.
// Scroll: volume ±5%. Middle click: mute.
import QtQuick
import Quickshell
import Quickshell.Bluetooth
import "../../config"
import "../../components"
import "../../widgets/network"
import "../../widgets/sound"
import "../../widgets/battery"

BarItem {
  id: root

  padding: 6
  accessibleName: "Status: " + networkText + ", volume " + Sound.volume + " percent" + (Battery.hasBattery ? ", battery " + Battery.batteryLevel + " percent" : "")
  active: networkMenu.visible || soundMenu.visible || batteryMenu.visible

  readonly property string networkText: network.isWiredConnected ? "Ethernet"
                                       : network.activeNetwork ? "Wi-Fi " + network.activeNetwork.name
                                       : "offline"
  readonly property BluetoothAdapter adapter: Bluetooth.defaultAdapter
  readonly property int btConnected: Bluetooth.devices.values.filter(d => d.connected).length

  onScrolled: wheel => Sound.setVolume(Sound.volume / 100 + (wheel.angleDelta.y > 0 ? 0.05 : -0.05))
  onClicked: mouse => { if (mouse.button === Qt.MiddleButton) Sound.toggleMute(); }

  NetworkManager {
    id: network
  }

  component Segment: Item {
    id: seg
    property string icon
    property color iconColor: Theme.text
    property bool clickable: true
    signal activated()

    width: 26
    height: 26
    anchors.verticalCenter: parent.verticalCenter

    Rectangle {
      anchors.fill: parent
      radius: 13
      color: segMouse.containsMouse && seg.clickable ? Theme.item : "transparent"
      Behavior on color { ColorAnimation { duration: Theme.anim.fast } }
    }

    Icon {
      anchors.centerIn: parent
      name: seg.icon
      size: 15
      color: seg.iconColor
    }

    MouseArea {
      id: segMouse
      anchors.fill: parent
      hoverEnabled: true
      enabled: seg.clickable
      cursorShape: Qt.PointingHandCursor
      onClicked: seg.activated()
    }
  }

  Segment {
    id: netSeg
    icon: network.isWiredConnected ? "ethernet" : network.activeNetwork ? "wifi" : "wifi-off"
    iconColor: network.isWiredConnected || network.activeNetwork ? Theme.text : Theme.subtext
    onActivated: networkMenu.visible = !networkMenu.visible
  }

  Segment {
    visible: root.adapter !== null && root.adapter.enabled
    icon: "bluetooth"
    iconColor: root.btConnected > 0 ? Theme.accent : Theme.text
    // Bluetooth details come with the quick settings panel
    clickable: false
  }

  Segment {
    id: soundSeg
    icon: Sound.isMuted ? "volume-off" : Sound.volume > 60 ? "volume-high" : "volume"
    iconColor: Sound.isMuted ? Theme.subtext : Theme.text
    onActivated: soundMenu.visible = !soundMenu.visible
  }

  Segment {
    id: batterySeg
    visible: Battery.hasBattery
    icon: "battery"
    iconColor: Battery.charging ? Theme.good : Battery.batteryLevel <= 15 ? Theme.error : Theme.text
    onActivated: batteryMenu.visible = !batteryMenu.visible
  }

  NetworkDropdown {
    id: networkMenu
    visible: false
    networkData: network
    anchor.item: netSeg
    anchor.rect.width: netSeg.width
    anchor.rect.height: netSeg.height
    anchor.edges: Edges.Bottom | Edges.Right
    anchor.gravity: Edges.Bottom | Edges.Left
    anchor.margins.top: 14
  }

  SoundDropdown {
    id: soundMenu
    visible: false
    anchor.item: soundSeg
    anchor.rect.width: soundSeg.width
    anchor.rect.height: soundSeg.height
    anchor.edges: Edges.Bottom | Edges.Right
    anchor.gravity: Edges.Bottom | Edges.Left
    anchor.margins.top: 14
  }

  BatteryDropdown {
    id: batteryMenu
    visible: false
    anchor.item: batterySeg
    anchor.rect.width: batterySeg.width
    anchor.rect.height: batterySeg.height
    anchor.edges: Edges.Bottom | Edges.Right
    anchor.gravity: Edges.Bottom | Edges.Left
    anchor.margins.top: 14
  }
}
