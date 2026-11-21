// PillSlider.qml
// The quick settings slider: a pill that fills up, icon on the left, value
// on the right. Drag, click or scroll. value is 0…1; moved(value) fires on input.
//
// Bind value to your state and update that state in onMoved. The slider never
// overwrites value itself; while you drag (and briefly after) it shows where
// your finger is, so slow replies (a media player over D-Bus) can't make it jump.
// throttle: at most one moved() per this many ms while dragging (0 = every
// step); the last value is always sent.
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
  property int throttle: 0

  signal moved(real value)

  // What you're dragging to, shown instead of value while you interact
  property real pending: 0
  readonly property bool interacting: drag.pressed || hold.running
  readonly property real shownValue: interacting ? pending : value

  implicitHeight: Theme.size.slider
  implicitWidth: 240

  Accessible.role: Accessible.Slider
  Accessible.name: label
  activeFocusOnTab: true
  Keys.onLeftPressed: set(shownValue - step)
  Keys.onRightPressed: set(shownValue + step)

  function set(v: real): void {
    pending = Math.max(0, Math.min(1, v));
    hold.restart();
    if (throttle <= 0) {
      moved(pending);
    } else if (!throttleTimer.running) {
      moved(pending);
      throttleTimer.dirty = false;
      throttleTimer.start();
    } else {
      throttleTimer.dirty = true;
    }
  }

  // Sends the newest value when the throttle window ends
  Timer {
    id: throttleTimer
    property bool dirty: false
    interval: Math.max(1, root.throttle)
    onTriggered: {
      if (!dirty) return;
      dirty = false;
      root.moved(root.pending);
      start();
    }
  }

  // Keep showing your value a moment after you let go, until the reply is in
  Timer {
    id: hold
    interval: 400
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
      width: Math.max(height, parent.width * root.shownValue)
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
    text: Math.round(root.shownValue * 100) + "%"
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
    onReleased: {
      // The last position always goes out, even inside the throttle window
      if (throttleTimer.dirty) {
        throttleTimer.stop();
        throttleTimer.dirty = false;
        root.moved(root.pending);
      }
    }
    onWheel: wheel => root.set(root.shownValue + (wheel.angleDelta.y > 0 ? root.step : -root.step))
  }
}
