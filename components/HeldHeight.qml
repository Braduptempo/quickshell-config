// HeldHeight.qml
// The height for a panel's window while the panel inside animates its own
// height. Resizing a Wayland window every frame makes the content shake, so
// the window grows at once (it's transparent) and only shrinks after the
// panel's animation has finished.
//   HeldHeight { id: held; target: card.implicitHeight; delay: Theme.anim.panelIn }
//   implicitHeight: held.value + 24
import QtQuick

QtObject {
  id: root

  property real target: 0
  // How long the panel's own animation takes
  property int delay: 200
  property real value: 0

  onTargetChanged: {
    if (target >= value) {
      shrink.stop();
      value = target;
    } else {
      shrink.interval = delay + 40;
      shrink.restart();
    }
  }

  property Timer shrink: Timer {
    onTriggered: root.value = root.target
  }

  Component.onCompleted: value = target
}
