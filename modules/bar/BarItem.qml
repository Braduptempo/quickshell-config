// BarItem.qml
// A 30 px pill inside the bar. Put icons and labels inside it.
// `active` marks it as open (e.g. its panel is showing).
import QtQuick
import "../../config"
import "../../components"

Item {
  id: root

  property bool active: false
  property bool flat: false
  property int padding: 12
  property string accessibleName
  property color activeColor: Theme.accent
  readonly property bool hovered: mouse.containsMouse
  default property alias content: row.data

  signal clicked(var mouse)
  signal scrolled(var wheel)

  implicitHeight: Theme.size.barItem
  implicitWidth: Math.max(implicitHeight, row.implicitWidth + padding * 2)
  // Grows and shrinks smoothly when something comes or goes (the moon by
  // the clock, a muted mic…); the content is clipped while it does
  Behavior on implicitWidth { NumberAnimation { duration: Theme.anim.segment; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.anim.standard } }
  clip: true

  Accessible.role: Accessible.Button
  Accessible.name: accessibleName

  Rectangle {
    anchors.fill: parent
    radius: Theme.pill(height)
    color: root.active ? Theme.alpha(root.activeColor, 0.16)
         : root.flat && !Theme.barPills ? (root.hovered ? Theme.item : "transparent")
         : root.hovered ? Theme.hover(Theme.barItem) : Theme.barItem
    border.width: 1
    border.color: root.active ? root.activeColor : Theme.barPills && Theme.borders ? Theme.border : "transparent"

    Behavior on color { ColorAnimation { duration: Theme.anim.fast } }
    Behavior on border.color { ColorAnimation { duration: Theme.anim.fast } }
  }

  SmoothRow {
    id: row
    anchors.centerIn: parent
    spacing: 8
  }

  MouseArea {
    id: mouse
    anchors.fill: parent
    hoverEnabled: true
    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
    cursorShape: Qt.PointingHandCursor
    onClicked: event => root.clicked(event)
    onWheel: event => root.scrolled(event)
  }
}
