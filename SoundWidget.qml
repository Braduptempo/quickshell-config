import QtQuick
import Quickshell
import QtQuick.Layouts

Item {
  id: root

  implicitWidth: soundLayout.implicitWidth + 20
  implicitHeight: soundLayout.implicitHeight + 10

  Rectangle {
    anchors.fill: parent
    color: "#2a2a2c"
    border.color: "blue"
    border.width: 3
    radius: 15
  }

  RowLayout {
    id: soundLayout

    anchors.fill: parent

    anchors.leftMargin:10
    anchors.rightMargin: 10
    anchors.topMargin: 5
    anchors.bottomMargin: 5

    spacing: 8

    Text {
      font.family: "jetbrains mono"
      font.pixelSize: 11
      color: "#ffffff"

      text: " " + Sound.volume + "%"
    }
  }
}
