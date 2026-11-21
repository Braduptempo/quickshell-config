// SmoothRow.qml
// A Row that doesn't jump: an item that appears (or becomes visible) pops in
// with a fade and a small scale, and the others slide aside to make room.
// Durations follow Settings → Animations, so "Off" turns it off.
import QtQuick
import "../config"

Row {
  add: Transition {
    NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Theme.anim.segment; easing.type: Easing.OutCubic }
    NumberAnimation { property: "scale"; from: 0.6; to: 1; duration: Theme.anim.segment; easing.type: Easing.OutBack }
  }
  move: Transition {
    NumberAnimation { properties: "x,y"; duration: Theme.anim.segment; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.anim.standard }
  }
}
