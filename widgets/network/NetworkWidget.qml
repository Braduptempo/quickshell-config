// NetworkWidget.qml
import QtQuick
import QtQuick.Layouts
import Quickshell

Item {
  id: root

  Text {
    font.family: "jetbrains mono"
    font.pixelSize: 11
  }

  implicitWidth: widgetLayout.implicitWidth + 20
  implicitHeight: widgetLayout.implicitHeight + 10

  NetworkManager {
    id: networkManager
  }

  Rectangle {
    anchors.fill: parent

    color: "#802a2a3c"          // Vulkleur (Fill)
    border.color: "blue"    // Randkleur (Border)
    border.width: 3            // Randdikte
    radius: 30                  // Afgeronde hoeken
  }

  RowLayout {
    id: widgetLayout
    anchors.fill: parent
    spacing:8
    anchors.leftMargin: 10   // Afstand vanaf de linker rand
    anchors.rightMargin: 10  // Afstand vanaf de rechter rand
    anchors.topMargin: 2     // Afstand vanaf de bovenrand
    anchors.bottomMargin: 2  // Afstand vanaf de onderrand

    // Het Icoontje
    Text {
      id: textIcon
      text: {
        if (networkManager.isWiredConnected) return "󰈀"; // Material Design Ethernet Icoon
        if (networkManager.activeNetwork) return networkManager.getWifiIcon(networkManager.activeNetwork.strength);
        return "󰤯"; // Geen verbinding icoon
      }
      color: "#ffffff"
      font.family: "jetbrains mono"
      font.pixelSize: 13
    }

    // De Tekst
    Text {
      text: {
        if (networkManager.isWiredConnected) return "Ethernet";
        if (networkManager.activeNetwork) return networkManager.activeNetwork.name;
        return "Niet verbonden";
      }
      color: "#ffffff"
      font.family: "jetbrains mono"
      font.pixelSize: 11
    }
  }

  MouseArea {
    anchors.fill: parent
    cursorShape: Qt.PointingHandCursor

    onClicked: {
      // GEFIXT: We koppelen de popup nu direct aan het 'barWindow' ID uit Bar.qml!
      if (!networkMenu.anchor.window) {
        networkMenu.anchor.window = barWindow;
      }

      // Geef de X, Y, Breedte en Hoogte van deze specifieke knop binnen het venster door
      networkMenu.anchor.rect = Qt.rect(root.x, root.y, root.width, root.height);

      networkMenu.anchor.margins.top = 30;

      // Open of sluit de popup
      networkMenu.visible = !networkMenu.visible;
    }
  }

  NetworkDropdown {
    id:networkMenu
    visible: false

    networkData: networkManager

    anchor.window: panel
    anchor.edges: panel.Edges.Bottom
  }
}
