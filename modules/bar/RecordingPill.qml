// RecordingPill.qml
// Shows while recording: a red dot, the time, pause and stop.
// Click the time to stop; the buttons pause/resume and stop.
import QtQuick
import "../../config"
import "../../components"
import "../../services"

BarItem {
  id: root

  visible: Capture.recording
  padding: 6
  active: true
  activeColor: Theme.error
  accessibleName: (Capture.paused ? "Recording paused at " : "Recording, ") + Capture.elapsedText

  onClicked: Capture.stop()

  Rectangle {
    width: 8
    height: 8
    radius: Theme.r(4)
    color: Capture.paused ? Theme.subtext : Theme.error
    anchors.verticalCenter: parent.verticalCenter

    SequentialAnimation on opacity {
      running: Capture.recording && !Capture.paused && Theme.speed > 0
      loops: Animation.Infinite
      NumberAnimation { to: 0.35; duration: 700; easing.type: Easing.InOutSine }
      NumberAnimation { to: 1; duration: 700; easing.type: Easing.InOutSine }
    }
  }

  Label {
    text: Capture.elapsedText
    font.weight: Font.Bold
    font.pixelSize: Theme.font.small
    color: Capture.paused ? Theme.subtext : Theme.text
    anchors.verticalCenter: parent.verticalCenter
  }

  IconButton {
    size: 22
    variant: "plain"
    icon: Capture.paused ? "play" : "pause"
    accessibleName: Capture.paused ? "Resume recording" : "Pause recording"
    anchors.verticalCenter: parent.verticalCenter
    onClicked: Capture.pause()
  }

  IconButton {
    size: 22
    variant: "plain"
    icon: "stop"
    accessibleName: "Stop recording"
    anchors.verticalCenter: parent.verticalCenter
    onClicked: Capture.stop()
  }
}
