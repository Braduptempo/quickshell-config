// BatteryDropdown.qml
import QtQuick
import Quickshell
import QtQuick.Layouts
import Quickshell.Services.UPower

PopupWindow {
  id: popup

  color: "transparent"

  // De grootte van ons popup-venstertje
  implicitWidth: 150
  implicitHeight: contentColumn.implicitHeight + 20

  // Geef de popup aan de onderkant van de knop weer
  // anchor.edges: Edges.Bottom

  // Sluit de popup automatisch als je ergens anders op je scherm klikt
  // onActiveChanged: {
  //     if (!active) {
  //         popup.visible = false
  //     }
  // }

  // De styling van de popup-box
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

    Text{
      text: Battery.charging ? "Charging" : "Discharging"
      font.bold: true
      color: "white"
    }

    // Tijd resterend / tijd tot vol
    Text {
      text: Battery.timeRemainingStr
      color: "#ffffff"
      font.pixelSize: 12
    }

    Rectangle {
      Layout.fillWidth: true
      height: 1
      color: "#ffffff"
    }

    // Lijst met alle individuele batterijen (Batterij 1, Batterij 2, etc.)
    Repeater {
      model: Battery.allDevices

      delegate: ColumnLayout {
        Layout.fillWidth: true
        spacing: 2

        // Filter zodat we alleen batterijen tonen (en niet je draadloze muis)
        visible: modelData.type === UPowerDeviceType.Battery

        Text {
          // modelData.model is de naam (bijv. "BAT0"), index + 1 geeft "Battery 1"
          text: `Battery ${index + 1} (${modelData.model})`
          font.pixelSize: 11
          color: "#ffffff"
        }

        Text {
          text: `${Math.floor(modelData.percentage * 100)}% - ${modelData.state === UPowerDeviceState.Charging ? "Charging" : "In use"}`
          font.pixelSize: 11
          color: "#ffffff"
        }
      }
    }
  }
}

