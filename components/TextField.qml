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
  // Pass Lock.capsLock: a password field then says when Caps Lock is on
  property bool capsLock: false
  readonly property bool showCaps: password && capsLock

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
    anchors.rightMargin: root.showCaps ? capsPill.width + 22 : 16
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

  Rectangle {
    id: capsPill
    visible: root.showCaps
    anchors.right: parent.right
    anchors.rightMargin: 6
    anchors.verticalCenter: parent.verticalCenter
    implicitWidth: capsRow.implicitWidth + 16
    implicitHeight: Math.min(24, parent.height - 8)
    radius: Theme.pill(height)
    color: Theme.alpha(Theme.warn, 0.16)

    Accessible.role: Accessible.AlertMessage
    Accessible.name: "Caps Lock is on"

    Row {
      id: capsRow
      anchors.centerIn: parent
      spacing: 5
      Icon { name: "caps"; size: 12; color: Theme.warn; anchors.verticalCenter: parent.verticalCenter }
      Label { text: "Caps Lock"; color: Theme.warn; font.pixelSize: Theme.font.label; anchors.verticalCenter: parent.verticalCenter }
    }
  }
}
