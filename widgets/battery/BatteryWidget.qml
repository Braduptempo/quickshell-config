// BatteryWidget.qml
import QtQuick
import QtQuick.Layouts
import Quickshell

Item {
  id: root

  implicitWidth: widgetLayout.implicitWidth + 20
  implicitHeight: widgetLayout.implicitHeight + 10

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

    Text {
      id: textIcon
      text: (Battery.displayPercentage === 100) ? "\uf240" : Battery.iconMap[Battery.displayPercentage]
      color: Battery.charging ? "green" : "white"
    }

    Text {
      id: textPercent
      text: Battery.batteryLevel + "%"
      color: "white"
    }
  }

  MouseArea {
    anchors.fill: parent
    cursorShape: Qt.PointingHandCursor

    onClicked: {
      // GEFIXT: We koppelen de popup nu direct aan het 'barWindow' ID uit Bar.qml!
      if (!batteryMenu.anchor.window) {
        batteryMenu.anchor.window = barWindow;
      }

      // Geef de X, Y, Breedte en Hoogte van deze specifieke knop binnen het venster door
      batteryMenu.anchor.rect = Qt.rect(root.x, root.y, root.width, root.height);

      batteryMenu.anchor.margins.top = 30;

      // Open of sluit de popup
      batteryMenu.visible = !batteryMenu.visible;
    }
  }

  BatteryDropdown {
    id: batteryMenu
    visible: false

    anchor.window: panel
    anchor.edges: panel.Edges.Bottom
  }

  // PopupWindow {
  // id: popup
  //visible: false

  //width: 150
  //height: 60

  // Plak hem netjes aan de onderkant van de bar
  //anchor.edges: panel.Edges.Bottom
  // anchor.window: panel

  // De styling van de popup-box
  //Rectangle {
  //anchors.fill: parent
  //color: "#ffffff"
  //border.color: "#333333"
  //border.width: 2
  // radius: 8

  //Text {
  // anchors.centerIn: parent
  //  text: "Hallo Wereld! 👋"
  //   color: "black"
  //    font.pixelSize: 14
  //   }
  // }
  //}
}

