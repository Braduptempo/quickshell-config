import Quickshell
import QtQuick
import Quickshell.Networking
import Quickshell.Io

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

  readonly property bool hasWiredDevice: wiredDevices.length > 0
  readonly property bool hasWifiDevice: wifiDevices.length > 0
  readonly property string wiredName: mainWiredDevice ? mainWiredDevice.name : ""
  readonly property string wifiName: mainWifiDevice ? mainWifiDevice.name : ""

  // Interface of the default route with the lowest metric: the connection
  // that actually carries the traffic (e.g. enp6s0 while Wi-Fi is also up)
  property string routeDevice: ""

  // "ethernet", "wifi" or "none"
  readonly property string primary: {
    if (routeDevice !== "" && routeDevice === wiredName) return "ethernet";
    if (routeDevice !== "" && routeDevice === wifiName) return "wifi";
    // No route info yet, or a route over another interface (VPN, tether)
    if (isWiredConnected) return "ethernet";
    if (activeNetwork) return "wifi";
    return "none";
  }

  Process {
    id: routeProcess
    command: ["ip", "-j", "route", "show", "default"]
    stdout: StdioCollector {
      onStreamFinished: {
        let routes = [];
        try {
          routes = JSON.parse(text);
        } catch (e) {
          routes = [];
        }
        let best = null;
        for (const r of routes) {
          if (!best || (r.metric ?? 0) < (best.metric ?? 0)) best = r;
        }
        root.routeDevice = best ? best.dev : "";
      }
    }
  }

  // Routes change when a cable is (un)plugged or Wi-Fi connects; 5 s is enough
  Timer {
    interval: 5000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: routeProcess.running = true
  }

  // Check right away when something visible changes
  onIsWiredConnectedChanged: routeProcess.running = true
  onActiveNetworkChanged: routeProcess.running = true

  // NIEUW: Houdt constant de sterkte van je huidige verbinding bij
  property int currentActiveSignal: 0

  Process {
    id: activeSignalProcess
    // Haal puur het signaalcijfer op van het netwerk waar 'active = yes' is
    command: ["bash", "-c", "nmcli -t -f active,signal dev wifi 2>/dev/null | awk -F: '$1==\"yes\" {print $2; exit}'"]
    stdout: SplitParser {
      onRead: data => {
        let sig = parseInt(data.trim());
        if (!isNaN(sig)) root.currentActiveSignal = sig;
      }
    }
  }

  // Poll het actieve signaal elke 3 seconden
  Timer {
    interval: 3000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: activeSignalProcess.running = true
  }

  // Blijft zoeken tot NetworkManager wakker is, en stopt dan!
  Timer {
    id: startupTimer
    interval: 500
    running: true
    repeat: true
    onTriggered: {
      sortDevices();
      if (wifiDevices.length > 0 || wiredDevices.length > 0) {
        running = false;
      }
    }
  }

  property int deviceCount: Networking.devices.values.length

  Component.onCompleted: {
    sortDevices();
  }

  // NIEUW: Helper-functie om het juiste icoontje te bepalen op basis van sterkte (0.0 tot 1.0)
  function getWifiIcon(signal) {
    if (signal === undefined || signal === null) return "󰤯";
    if (signal > 80) return "󰤨"; // 4 streepjes
    if (signal > 60) return "󰤥"; // 3 streepjes
    if (signal > 40) return "󰤢"; // 2 streepjes
    if (signal > 20) return "󰤟"; // 1 streepje

    return "󰤯"; // 0 streepjes
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
  }
  property bool isWifiOn: true

  readonly property var iconMap: {
    "0": ""
  }
}
