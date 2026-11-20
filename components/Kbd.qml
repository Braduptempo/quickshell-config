// Kbd.qml
// A key or shortcut, e.g. "Super + T".
import QtQuick
import "../config"

Rectangle {
  property alias text: label.text

  implicitHeight: 22
  implicitWidth: label.implicitWidth + 16
  radius: Theme.pill(height)
  color: Theme.overlay

  Label {
    id: label
    anchors.centerIn: parent
    kind: "label"
    font.capitalization: Font.MixedCase
    font.letterSpacing: 0
    font.weight: Font.Normal
    color: Theme.text
  }
}
