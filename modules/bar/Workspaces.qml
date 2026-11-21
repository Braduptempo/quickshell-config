// Workspaces.qml
// Dots for the workspaces on this monitor. Active = wide accent pill,
// occupied = light dot, empty = dark dot. Click to go there, scroll to step.
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Hyprland
import "../../config"
import "../../services"

Item {
  id: root

  required property ShellScreen screen
  readonly property HyprlandMonitor monitor: Hyprland.monitorFor(screen)
  readonly property int activeId: monitor?.activeWorkspace?.id ?? -1

  implicitHeight: Theme.size.barItem
  implicitWidth: dots.implicitWidth + 24

  Accessible.role: Accessible.PageTabList
  Accessible.name: "Workspaces"

  Rectangle {
    anchors.fill: parent
    radius: Theme.pill(height)
    color: Theme.barItem
    border.width: Theme.barPills && Theme.borders ? 1 : 0
    border.color: Theme.border
  }

  MouseArea {
    anchors.fill: parent
    onWheel: wheel => Hypr.focusWorkspace(wheel.angleDelta.y > 0 ? "m-1" : "m+1")
  }

  Row {
    id: dots
    anchors.centerIn: parent
    spacing: 6

    Repeater {
      model: Hyprland.workspaces

      Rectangle {
        id: dot
        required property HyprlandWorkspace modelData

        readonly property bool current: modelData.id === root.activeId
        readonly property bool occupied: modelData.toplevels.values.length > 0
        // Only normal workspaces of this monitor; special ones have id < 0
        visible: modelData.id > 0 && (!root.monitor || modelData.monitor === root.monitor)

        width: current ? 28 : 12
        height: 12
        radius: Theme.r(6)
        color: current ? Theme.accent
             : dotMouse.containsMouse ? Theme.text
             : occupied ? Theme.subtext : Theme.overlay

        Accessible.role: Accessible.PageTab
        Accessible.name: "Workspace " + modelData.id + (current ? ", active" : occupied ? ", occupied" : ", empty")

        Behavior on width {
          NumberAnimation { duration: Theme.anim.panelIn; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.anim.standard }
        }
        Behavior on color { ColorAnimation { duration: Theme.anim.fast } }

        MouseArea {
          id: dotMouse
          anchors.fill: parent
          anchors.margins: -4
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: Hypr.focusWorkspace(dot.modelData.id)
        }
      }
    }
  }
}
