// SmoothRow.qml
// A Row that doesn't jump: an item that appears (or becomes visible) pops in
// with a fade and a small scale, and the others slide aside to make room.
// slide: false for a row anchored on the right (or centred): there the row
// itself moves when it grows, so sliding from the old positions would make
// the items jump one way and slide back the other.
// Durations follow Settings → Animations, so "Off" turns it off.
import QtQuick
import "../config"

Row {
  id: root
  property bool slide: true

  add: Transition {
    NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Theme.anim.segment; easing.type: Easing.OutCubic }
    NumberAnimation { property: "scale"; from: 0.6; to: 1; duration: Theme.anim.segment; easing.type: Easing.OutBack }
  }
  move: root.slide ? slideAside : null

  property Transition slideAside: Transition {
    NumberAnimation { properties: "x,y"; duration: Theme.anim.segment; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.anim.standard }
  }
}
