// Bar.qml

import QtQuick
import Quickshell
import Quickshell.Wayland
import QtQuick.Layouts

import "./widgets/network"
import "./widgets/battery"
import "./widgets/sound"
import "./widgets/clock"
import "./widgets/workspaces"

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

      RowLayout {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: 10
        spacing: 10

        WorkspaceWidget {}
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
    }
  }
}
