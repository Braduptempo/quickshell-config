import Quickshell
import QtQuick
import Quickshell.Networking

Item {
  id: root

  property var wiredDevices: []
  property var wifiDevices: []

  // Omdat we in dit voorbeeld vooral met Wi-Fi werken, pakken we de eerste
  property var mainWifiDevice: wifiDevices.length > 0 ? wifiDevices[0] : null

  // De uiteindelijke lijst met netwerken die de UI mag uitlezen
  property var availableNetworks: mainWifiDevice ? mainWifiDevice.networks.values : []

  // NIEUW: Bedrade (Ethernet) check
  property var mainWiredDevice: wiredDevices.length > 0 ? wiredDevices[0] : null
  property bool isWiredConnected: mainWiredDevice ? mainWiredDevice.hasLink : false

  // NIEUW: Filtert automatisch het netwerk waar je momenteel mee verbonden bent
  property var activeNetwork: {
    for (let i = 0; i < availableNetworks.length; i++) {
      if (availableNetworks[i].connected) {
        return availableNetworks[i];
      }
    }
    return null;
  }

  property int deviceCount: Networking.devices.values.length

  Component.onCompleted: {
    sortDevices();
  }

  // NIEUW: Helper-functie om het juiste icoontje te bepalen op basis van sterkte (0.0 tot 1.0)
  function getWifiIcon(strength) {
    if (strength === undefined || strength === null) return "󰤯"; // Offline of onbekend
    if (strength > 0.8) return "󰤨"; // 4 streepjes
    if (strength > 0.6) return "󰤥"; // 3 streepjes
    if (strength > 0.4) return "󰤢"; // 2 streepjes
    if (strength > 0.2) return "󰤟"; // 1 streepje
    return "󰤯";                     // 0 streepjes
  }

  function sortDevices(){
    let allDevices = Networking.devices.values;
    let wifis = [];
    let wireds = [];

    for (let i = 0; i < allDevices.length; i++) {
      let device = allDevices[i];

      if (device.type === DeviceType.Wifi) {
        device.scannerEnabled = true;
        wifis.push(device);
      } else if (device.type === DeviceType.Wired) {
        wireds.push(device);
      }
    }

    wifiDevices = wifis;
    wiredDevices = wireds;

    console.log("Wi-Fi adapters gevonden:", wifiDevices.length);
    console.log("Bedrade adapters gevonden:", wiredDevices.length);
  }

  onAvailableNetworksChanged: {
    for (let i = 0; i < availableNetworks.length; i++) {
      let network = availableNetworks[i];

      // FIX 1: 'net' is overal veranderd naar 'network'
      console.log("Gevonden netwerk:", network.name);
      console.log("Is verbonden:", network.connected);
      console.log("Is een bekend netwerk:", network.known);
      console.log("Connection strength:" , network.WifiNetwork.signalStrength);
    }
  }
  property bool isWifiOn: true

  readonly property var iconMap: {
    "0": ""
  }
}
