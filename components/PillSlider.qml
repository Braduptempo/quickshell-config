// PillSlider.qml
// The quick settings slider: a pill that fills up, icon on the left, value
// on the right. Drag, click or scroll. value is 0…1; moved(value) fires on input.
import QtQuick
import "../config"

Item {
  id: root

  property real value: 0.5
  property string icon
  property string label
  property color fillColor: Theme.accent
  property bool showValue: true
  property real step: 0.05

  signal moved(real value)

  implicitHeight: Theme.size.slider
  implicitWidth: 240

  Accessible.role: Accessible.Slider
  Accessible.name: label
  activeFocusOnTab: true
  Keys.onLeftPressed: set(value - step)
  Keys.onRightPressed: set(value + step)

  function set(v: real): void {
    const clamped = Math.max(0, Math.min(1, v));
    value = clamped;
    moved(clamped);
  }

  Rectangle {
    id: track
    anchors.fill: parent
    radius: Theme.pill(height)
    color: Theme.item
    clip: true
    border.width: root.activeFocus ? 1 : 0
    border.color: Theme.accent

    Rectangle {
      height: parent.height
      width: Math.max(height, parent.width * root.value)
      radius: Theme.pill(height)
      color: root.fillColor

      Behavior on width {
        enabled: !drag.pressed
        NumberAnimation { duration: Theme.anim.toggle; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.anim.standard }
      }
    }
  }

  Icon {
    visible: root.icon !== ""
    name: root.icon
    size: 16
    strokeWidth: 2.2
    color: Theme.onAccent
    anchors.left: parent.left
    anchors.leftMargin: (root.height - size) / 2
    anchors.verticalCenter: parent.verticalCenter
  }

  Label {
    visible: root.showValue
    text: Math.round(root.value * 100) + "%"
    kind: "small"
    font.weight: Font.Bold
    anchors.right: parent.right
    anchors.rightMargin: 14
    anchors.verticalCenter: parent.verticalCenter
  }

  MouseArea {
    id: drag
    anchors.fill: parent
    cursorShape: Qt.PointingHandCursor
    onPressed: mouse => root.set(mouse.x / width)
    onPositionChanged: mouse => { if (pressed) root.set(mouse.x / width); }
    onWheel: wheel => root.set(root.value + (wheel.angleDelta.y > 0 ? root.step : -root.step))
  }
}
