// NetworkDropdown.qml
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Networking
import Quickshell.Hyprland
import Quickshell.Io

PopupWindow {
  id: popup
  color: "transparent"
  implicitWidth: 300
  implicitHeight: contentColumn.implicitHeight + 20

  property var networkData: null

  HyprlandFocusGrab {
    active: popup.visible
    windows: [popup]
    onCleared: popup.visible = false;
  }

  // Live stats logica
  property var netStats: ({ connected: false })
  property double lastRx: 0
  property double lastTx: 0
  property double downSpeed: 0
  property double upSpeed: 0

  Timer {
    interval: 2000
    running: popup.visible
    repeat: true
    triggeredOnStart: true
    onTriggered: statsProcess.running = true
  }

  Process {
    id: statsProcess
    command: ["bash", "-c", "/home/$USER/.config/quickshell/scripts/netstats.sh"]
    stdout: SplitParser {
      onRead: (data) => {
        let json = JSON.parse(data);
        if (json.connected) {
          if (popup.lastRx > 0) {
            popup.downSpeed = (json.rx - popup.lastRx) / 2;
            popup.upSpeed = (json.tx - popup.lastTx) / 2;
          }
          popup.lastRx = json.rx;
          popup.lastTx = json.tx;
          popup.netStats = json;
        } else {
          popup.netStats = { connected: false };
          popup.downSpeed = 0;
          popup.upSpeed = 0;
        }
      }
    }
  }

  // Lijst filters
  property var allNetworks: networkData ? networkData.availableNetworks : []
  property var knownNetworks: allNetworks.filter(n => n.known || n.connected)
  property var unknownNetworks: allNetworks.filter(n => !n.known && !n.connected)

  // Layout
  Item {
    width: parent.width
    height: parent.height
    opacity: popup.visible ? 1 : 0
    y: popup.visible ? 0 : -20

    Behavior on opacity { NumberAnimation { duration: 250 } }
    Behavior on y { NumberAnimation { duration: 350; easing.type: Easing.OutCubic } }

    Rectangle {
      anchors.fill: parent
      color: "#2a2a2c"
      border.color: "#ffffff"
      border.width: 2
      radius: 8
      clip: true
    }

    ColumnLayout {
      id: contentColumn
      anchors.fill: parent
      anchors.margins: 10
      spacing: 8

      // Header
      RowLayout {
        Layout.fillWidth: true
        Layout.maximumHeight: 40
        spacing: 12

        Text {
          text: {
            if (networkData && networkData.isWiredConnected) return "󰈀";
            // GEFIXT: networkManager veranderd naar networkData
            if (networkData && networkData.activeNetwork) return networkData.getWifiIcon(networkData.currentActiveSignal);
            return "󰤯";
          }
          font.family: "jetbrains mono"
          font.pixelSize: 32; color: "#ffffff"
          Layout.alignment: Qt.AlignVCenter
        }

        Column {
          Layout.fillWidth: true; Layout.alignment: Qt.AlignVCenter; spacing: 0
          Text { text: "Wi-Fi & Networks"; font.pixelSize: 15; font.bold: true; color: "white"; width: parent.width; elide: Text.ElideRight; lineHeight: 15; lineHeightMode: Text.FixedHeight }
          Text {
            text: networkData && networkData.isWiredConnected ? "Connected: Ethernet" : (networkData && networkData.activeNetwork ? "Connected: " + networkData.activeNetwork.name : "Not connected")
            font.pixelSize: 11; color: "#a0a0a0"; width: parent.width; elide: Text.ElideRight; lineHeight: 12; lineHeightMode: Text.FixedHeight
          }
        }

        Switch {
          Layout.alignment: Qt.AlignVCenter; topPadding: 0; bottomPadding: 0; leftPadding: 0; rightPadding: 0
          checked: Networking.wifiEnabled
          onToggled: Networking.wifiEnabled = checked;
        }
      }

      Rectangle { Layout.fillWidth: true; height: 1; color: "#ffffff" }

      // Invoegen van je nieuwe Stats Paneel
      NetworkStatsPanel {
        netStats: popup.netStats
        downSpeed: popup.downSpeed
        upSpeed: popup.upSpeed
      }

      // OPGESLAGEN NETWERKEN
      RowLayout {
        Layout.fillWidth: true; Layout.topMargin: 12; Layout.bottomMargin: 4; visible: popup.knownNetworks.length > 0
        Text { text: "󰒋"; color: "#a6e3a1"; font.family: "jetbrains mono"; font.pixelSize: 12 }
        Text { text: "OPGESLAGEN NETWERKEN"; font.bold: true; color: "#a0a0a0"; font.pixelSize: 10; font.letterSpacing: 1 }
        Rectangle { Layout.fillWidth: true; height: 1; color: "#404040"; Layout.leftMargin: 6 }
      }
      Repeater {
        model: popup.knownNetworks
        delegate: NetworkRowDelegate {
          networkData: popup.networkData
          netStats: popup.netStats // <-- DEZE REGEL TOEGEVOEGD
        }
      }

      // ANDERE NETWERKEN
      RowLayout {
        Layout.fillWidth: true; Layout.topMargin: 12; Layout.bottomMargin: 4; visible: popup.unknownNetworks.length > 0
        Text { text: "󰤨"; color: "#89b4fa"; font.family: "jetbrains mono"; font.pixelSize: 12 }
        Text { text: "ANDERE NETWERKEN"; font.bold: true; color: "#a0a0a0"; font.pixelSize: 10; font.letterSpacing: 1 }
        Rectangle { Layout.fillWidth: true; height: 1; color: "#404040"; Layout.leftMargin: 6 }
      }
      Repeater {
        model: popup.unknownNetworks
        delegate: NetworkRowDelegate {
          networkData: popup.networkData
          netStats: popup.netStats // <-- DEZE REGEL TOEGEVOEGD
        }
      }
    }
  }
}
