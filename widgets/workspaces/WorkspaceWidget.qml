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
        // HyprlandWorkspace has no `windows` count; its windows are in `toplevels`
        property bool isOccupied: modelData.toplevels.values.length > 0
        property bool isHovered: wsMouse.containsMouse

        Layout.preferredWidth: visible ? (isCurrent ? 24 : 12) : 0
        Layout.preferredHeight: visible ? 12 : 0
        radius: 6

        // --- KLEUR LOGICA ---
        // Hover is part of the binding, so the colour keeps following the
        // active workspace (assigning colour in onEntered/onExited broke that)
        color: {
          if (isCurrent) return isHovered ? "#cba6f7" : "#ffffff"; // Actief
          if (isOccupied) return isHovered ? "#ffffff" : "#bac2de"; // Bezet: Lichtgrijs
          return isHovered ? "#a6adc8" : "#585b70";                // Leeg: Donkergrijs
        }

        Behavior on Layout.preferredWidth { NumberAnimation { duration: 250; easing.type: Easing.OutQuint } }
        Behavior on color { ColorAnimation { duration: 250 } }

        MouseArea {
          id: wsMouse
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor

          onClicked: Hyprland.dispatch("workspace " + modelData.id)
        }
      }
    }
  }
}
