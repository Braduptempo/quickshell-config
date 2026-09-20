import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

Item {
  id: root

  implicitWidth: layout.implicitWidth + 20
  implicitHeight: layout.implicitHeight + 10

  // --- DE FIX: We kijken globaal welk werkblad actief is.
  // Omdat dit bovenaan staat, breekt de live-verbinding nooit!
  property int activeWsId: Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id : -1

  Process {
    id: dispatchProcess
    property string targetWs: ""
    command: ["hyprctl", "dispatch", "workspace", targetWs]
  }

  Rectangle {
    anchors.fill: parent
    color: "#2a2a2c"
    border.color: "#ffffff"
    border.width: 3
    radius: 15
  }

  RowLayout {
    id: layout
    anchors.fill: parent
    anchors.leftMargin: 10
    anchors.rightMargin: 10
    anchors.topMargin: 5
    anchors.bottomMargin: 5
    spacing: 8

    Repeater {
      model: Hyprland.workspaces

      delegate: Rectangle {
        visible: modelData.id > 0

        // --- STATUS CONTROLES ---
        // We vergelijken het ID van dit bolletje met de globale variabele bovenin
        property bool isCurrent: modelData.id === root.activeWsId
        property bool isOccupied: modelData.windows > 0

        Layout.preferredWidth: visible ? (isCurrent ? 24 : 12) : 0
        Layout.preferredHeight: visible ? 12 : 0
        radius: 6

        // --- KLEUR LOGICA ---
        color: {
          if (isCurrent) return "#ffffff";       // Actief: Paars
          if (isOccupied) return "#bac2de";      // Bezet: Lichtgrijs
          return "#585b70";                      // Leeg: Donkergrijs
        }

        Behavior on Layout.preferredWidth { NumberAnimation { duration: 250; easing.type: Easing.OutQuint } }
        Behavior on color { ColorAnimation { duration: 250 } }

        MouseArea {
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor

          onEntered: {
            if (parent.isCurrent) parent.color = "#cba6f7";
            else if (parent.isOccupied) parent.color = "#ffffff";
            else parent.color = "#a6adc8";
          }
          onExited: {
            if (parent.isCurrent) parent.color = "#cba6f7";
            else if (parent.isOccupied) parent.color = "#bac2de";
            else parent.color = "#585b70";
          }

          onClicked: {
            dispatchProcess.targetWs = modelData.id.toString();
            dispatchProcess.running = true;
          }
        }
      }
    }
  }
}
