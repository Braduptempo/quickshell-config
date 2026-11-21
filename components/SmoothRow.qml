// SmoothRow.qml
// A Row that doesn't jump: the others slide aside when an item comes or goes.
// (No fade in here: a Row's add transition stops halfway when the row moves
// again, and leaves the item half transparent. Pills fade in themselves:
// BarItem.appear.)
// slide: false for a row anchored on the right (or centred): there the row
// itself moves when it grows, so sliding from the old positions would make
// the items jump one way and slide back the other.
// Durations follow Settings → Animations, so "Off" turns it off.
import QtQuick
import "../config"

Row {
  id: root
  property bool slide: true

  move: root.slide ? slideAside : null

  property Transition slideAside: Transition {
    NumberAnimation { properties: "x,y"; duration: Theme.anim.segment; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.anim.standard }
  }
}
