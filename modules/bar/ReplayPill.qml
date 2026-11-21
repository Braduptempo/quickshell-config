// ReplayPill.qml
// While the replay buffer runs: a small pill with how much it keeps.
// Click: save it (also Alt + F10). Right click: stop the buffer.
import QtQuick
import "../../config"
import "../../components"
import "../../services"

BarItem {
  id: root

  visible: Capture.replaying
  padding: 10
  accessibleName: "Replay buffer, keeping the last " + label.text + ". Click to save, right click to stop"

  onClicked: mouse => {
    if (mouse.button === Qt.RightButton) Capture.stopReplay();
    else Capture.saveReplay();
  }

  Icon { name: "restart"; size: 14; color: Theme.warn; anchors.verticalCenter: parent.verticalCenter }
  Label {
    id: label
    text: Capture.replayActiveSeconds >= 60 ? (Capture.replayActiveSeconds / 60) + " min" : Capture.replayActiveSeconds + " s"
    color: Theme.warn
    font.pixelSize: Theme.font.small
    anchors.verticalCenter: parent.verticalCenter
  }
}
