// TextField.qml
// Pill input. `password: true` hides the text. accepted() fires on Enter.
import QtQuick
import "../config"

Rectangle {
  id: root

  property alias text: input.text
  property string placeholder
  property bool password: false
  property bool error: false

  signal accepted()

  function focusInput(): void {
    input.forceActiveFocus();
  }

  implicitHeight: Theme.size.input
  implicitWidth: 240
  radius: Theme.pill(height)
  color: Theme.alpha(Theme.crust, Theme.light ? 0.08 : 0.6)
  border.width: 1
  border.color: error ? Theme.error : input.activeFocus ? Theme.accent : Theme.overlay

  Behavior on border.color { ColorAnimation { duration: Theme.anim.fast } }

  TextInput {
    id: input
    anchors.fill: parent
    anchors.leftMargin: 16
    anchors.rightMargin: 16
    verticalAlignment: TextInput.AlignVCenter
    color: Theme.text
    selectionColor: Theme.alpha(Theme.accent, 0.4)
    font.family: Theme.font.family
    font.pixelSize: Theme.font.body
    font.letterSpacing: root.password && text !== "" ? 2 : 0
    echoMode: root.password ? TextInput.Password : TextInput.Normal
    clip: true
    onAccepted: root.accepted()

    Accessible.role: Accessible.EditableText
    Accessible.name: root.placeholder
  }

  Label {
    visible: input.text === "" && !input.activeFocus
    text: root.placeholder
    kind: "muted"
    anchors.left: parent.left
    anchors.leftMargin: 16
    anchors.verticalCenter: parent.verticalCenter
  }
}
