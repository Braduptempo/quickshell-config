// Bar.qml

import QtQuick
import Quickshell
import Quickshell.Wayland
import QtQuick.Layouts

import "./widgets/network"
import "./widgets/battery"
import "./widgets/sound"
import "./widgets/clock"

Scope {
  Variants {
    model: Quickshell.screens

    PanelWindow {
      id: panel
      required property var modelData
      color: "transparent"

      WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

      screen: modelData
      implicitHeight: 30

      anchors {
        top: true
        left: true
        right: true
      }

      ClockWidget {
        anchors.centerIn: parent
        color: "white"
      }

      RowLayout {
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.rightMargin: 10
        spacing: 8 // Vaste, mooie ruimte tussen de widgets onderling

        NetworkWidget {}
        BatteryWidget {}
        SoundWidget {}
      }

      Rectangle {
        id: openButton
        implicitWidth: 100
        implicitHeight: 30
        color: "royalblue"
        radius: 4

        Text {
          anchors.centerIn: parent
          text: myPopup.visible ? "Sluiten" : "Open Popup"
          color: "white"
        }

        MouseArea {
          anchors.fill: parent
          onClicked: myPopup.visible = !myPopup.visible
        }
      }

      PopupWindow {
        id: myPopup

        // 1. Koppel aan het panel
        anchor.window: panel

        // 2. Bepaal de positie t.o.v. het parent window (X en Y)
        anchor.rect.x: openButton.x
        anchor.rect.y: panel.height + 5

        implicitWidth: 200
        implicitHeight: 150

        // 3. Sluit automatisch bij klikken buiten de popup
        grabFocus: true

        // Inhoud van de popup
        Rectangle {
          anchors.fill: parent
          color: "#222222"
          border.color: "#444444"
          radius: 8

          Text {
            anchors.centerIn: parent
            text: "Hallo vanuit de popup!"
            color: "white"
          }
        }
      }
    }
  }
}
